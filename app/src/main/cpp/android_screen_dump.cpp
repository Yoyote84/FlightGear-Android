// Android implementation of SimGear's screen-dump API.
// GLES readback is kept here to avoid pulling the desktop osgDB writer/plugin stack
// into the Android native target. The output is a standards-compliant RGBA PNG.
#include <simgear/screen/screen-dump.hxx>

#include <GLES3/gl3.h>
#include <zlib.h>

#include <cstdint>
#include <cstring>
#include <fstream>
#include <limits>
#include <vector>

namespace {

void appendU32(std::vector<std::uint8_t>& output, std::uint32_t value)
{
    output.push_back(static_cast<std::uint8_t>((value >> 24) & 0xff));
    output.push_back(static_cast<std::uint8_t>((value >> 16) & 0xff));
    output.push_back(static_cast<std::uint8_t>((value >> 8) & 0xff));
    output.push_back(static_cast<std::uint8_t>(value & 0xff));
}

bool appendPngChunk(std::vector<std::uint8_t>& png,
                    const char type[4],
                    const std::uint8_t* data,
                    std::size_t size)
{
    if (size > std::numeric_limits<std::uint32_t>::max() ||
        size > std::numeric_limits<uInt>::max() - 4u) {
        return false;
    }

    appendU32(png, static_cast<std::uint32_t>(size));
    const std::size_t crcStart = png.size();
    png.insert(png.end(), type, type + 4);
    if (size != 0) {
        png.insert(png.end(), data, data + size);
    }

    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc,
                reinterpret_cast<const Bytef*>(png.data() + crcStart),
                static_cast<uInt>(4u + size));
    appendU32(png, static_cast<std::uint32_t>(crc));
    return true;
}

} // namespace

bool sg_glDumpWindow(const char* filename, int win_width, int win_height)
{
    if (filename == nullptr || filename[0] == '\0' ||
        win_width <= 0 || win_height <= 0) {
        return false;
    }

    const std::size_t width = static_cast<std::size_t>(win_width);
    const std::size_t height = static_cast<std::size_t>(win_height);
    const std::size_t maxSize = std::numeric_limits<std::size_t>::max();
    if (width > maxSize / 4u) {
        return false;
    }

    const std::size_t rowBytes = width * 4u;
    if (rowBytes == maxSize || rowBytes + 1u > maxSize / height) {
        return false;
    }

    const std::size_t pixelBytes = rowBytes * height;
    const std::size_t scanlineBytes = rowBytes + 1u;
    const std::size_t rawBytes = scanlineBytes * height;
    if (rawBytes > std::numeric_limits<uLong>::max() ||
        rawBytes > std::numeric_limits<uInt>::max()) {
        return false;
    }

    std::vector<std::uint8_t> pixels(pixelBytes);
    GLint previousPackAlignment = 4;
    glGetIntegerv(GL_PACK_ALIGNMENT, &previousPackAlignment);
    for (int i = 0; i < 16 && glGetError() != GL_NO_ERROR; ++i) {
        // Discard errors left by the previous GL caller.
    }
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glReadPixels(0, 0, win_width, win_height, GL_RGBA, GL_UNSIGNED_BYTE, pixels.data());
    const GLenum readError = glGetError();
    glPixelStorei(GL_PACK_ALIGNMENT, previousPackAlignment);
    if (readError != GL_NO_ERROR) {
        return false;
    }

    // PNG rows are stored top-to-bottom; OpenGL returns the bottom row first.
    std::vector<std::uint8_t> scanlines(rawBytes);
    for (std::size_t y = 0; y < height; ++y) {
        const std::size_t sourceY = height - 1u - y;
        const std::size_t destinationOffset = y * scanlineBytes;
        scanlines[destinationOffset] = 0; // PNG filter: None
        std::memcpy(scanlines.data() + destinationOffset + 1u,
                    pixels.data() + sourceY * rowBytes,
                    rowBytes);
    }

    uLongf compressedSize = compressBound(static_cast<uLong>(rawBytes));
    std::vector<std::uint8_t> compressed(static_cast<std::size_t>(compressedSize));
    const int compressionResult = compress2(
        compressed.data(),
        &compressedSize,
        scanlines.data(),
        static_cast<uLong>(rawBytes),
        Z_BEST_SPEED);
    if (compressionResult != Z_OK) {
        return false;
    }
    compressed.resize(static_cast<std::size_t>(compressedSize));

    static constexpr std::uint8_t signature[] = {
        0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a
    };
    std::vector<std::uint8_t> png(signature, signature + sizeof(signature));

    std::uint8_t header[13] = {};
    const auto storeBigEndian = [](std::uint8_t* destination, std::uint32_t value) {
        destination[0] = static_cast<std::uint8_t>((value >> 24) & 0xff);
        destination[1] = static_cast<std::uint8_t>((value >> 16) & 0xff);
        destination[2] = static_cast<std::uint8_t>((value >> 8) & 0xff);
        destination[3] = static_cast<std::uint8_t>(value & 0xff);
    };
    storeBigEndian(header, static_cast<std::uint32_t>(win_width));
    storeBigEndian(header + 4, static_cast<std::uint32_t>(win_height));
    header[8] = 8; // bit depth
    header[9] = 6; // RGBA
    if (!appendPngChunk(png, "IHDR", header, sizeof(header)) ||
        !appendPngChunk(png, "IDAT", compressed.data(), compressed.size()) ||
        !appendPngChunk(png, "IEND", nullptr, 0)) {
        return false;
    }

    std::ofstream output(filename, std::ios::binary | std::ios::trunc);
    if (!output) {
        return false;
    }
    output.write(reinterpret_cast<const char*>(png.data()),
                 static_cast<std::streamsize>(png.size()));
    return output.good();
}
