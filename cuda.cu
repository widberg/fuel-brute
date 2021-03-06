#include <cstdio>
#include <cstdint>
#include <cassert>

typedef std::uint32_t crc32_t;
#define CRC32_MAX (UINT32_MAX)
#define CRC32_MIN (UINT32_MIN)

__constant__ std::uint64_t HASHES_LEN;
__constant__ crc32_t* HASHES;

__constant__ std::uint64_t DICTIONARY_LEN;
__constant__ const char** DICTIONARY;

__host__
inline void cudaAssert(cudaError_t code, const char* file, int line)
{
    if (code != cudaSuccess)
    {
        fprintf(stderr, "CUDA_ASSERT: \"%s\" @ %s : %d\n", cudaGetErrorString(code), file, line);
        exit(code);
    }
}
#define CUDA_ASSERT(code) do { cudaAssert(code, __FILE__, __LINE__); } while(0)

__device__
inline void cudaDevAssert(cudaError_t code, const char* file, int line)
{
    if (code != cudaSuccess)
    {
        printf("CUDA_DEV_ASSERT: \"%s\" @ %s : %d\n", cudaGetErrorString(code), file, line);
        return;
    }
}
#define CUDA_DEV_ASSERT(code) do { cudaDevAssert(code, __FILE__, __LINE__); } while(0)

#define CRC32_POLYNOMIAL (0x04C11DB7U)
#define CRC32_TABLE_SIZE (256U)
__constant__
const crc32_t crc32_table[CRC32_TABLE_SIZE] = {
    0x00000000, 0x04C11DB7, 0x09823B6E, 0x0D4326D9, 0x130476DC, 0x17C56B6B, 0x1A864DB2, 0x1E475005,  //   0 [0x00 .. 0x07]
    0x2608EDB8, 0x22C9F00F, 0x2F8AD6D6, 0x2B4BCB61, 0x350C9B64, 0x31CD86D3, 0x3C8EA00A, 0x384FBDBD,  //   8 [0x08 .. 0x0F]
    0x4C11DB70, 0x48D0C6C7, 0x4593E01E, 0x4152FDA9, 0x5F15ADAC, 0x5BD4B01B, 0x569796C2, 0x52568B75,  //  16 [0x10 .. 0x17]
    0x6A1936C8, 0x6ED82B7F, 0x639B0DA6, 0x675A1011, 0x791D4014, 0x7DDC5DA3, 0x709F7B7A, 0x745E66CD,  //  24 [0x18 .. 0x1F]
    0x9823B6E0, 0x9CE2AB57, 0x91A18D8E, 0x95609039, 0x8B27C03C, 0x8FE6DD8B, 0x82A5FB52, 0x8664E6E5,  //  32 [0x20 .. 0x27]
    0xBE2B5B58, 0xBAEA46EF, 0xB7A96036, 0xB3687D81, 0xAD2F2D84, 0xA9EE3033, 0xA4AD16EA, 0xA06C0B5D,  //  40 [0x28 .. 0x2F]
    0xD4326D90, 0xD0F37027, 0xDDB056FE, 0xD9714B49, 0xC7361B4C, 0xC3F706FB, 0xCEB42022, 0xCA753D95,  //  48 [0x30 .. 0x37]
    0xF23A8028, 0xF6FB9D9F, 0xFBB8BB46, 0xFF79A6F1, 0xE13EF6F4, 0xE5FFEB43, 0xE8BCCD9A, 0xEC7DD02D,  //  56 [0x38 .. 0x3F]
    0x34867077, 0x30476DC0, 0x3D044B19, 0x39C556AE, 0x278206AB, 0x23431B1C, 0x2E003DC5, 0x2AC12072,  //  64 [0x40 .. 0x47]
    0x128E9DCF, 0x164F8078, 0x1B0CA6A1, 0x1FCDBB16, 0x018AEB13, 0x054BF6A4, 0x0808D07D, 0x0CC9CDCA,  //  72 [0x48 .. 0x4F]
    0x7897AB07, 0x7C56B6B0, 0x71159069, 0x75D48DDE, 0x6B93DDDB, 0x6F52C06C, 0x6211E6B5, 0x66D0FB02,  //  80 [0x50 .. 0x57]
    0x5E9F46BF, 0x5A5E5B08, 0x571D7DD1, 0x53DC6066, 0x4D9B3063, 0x495A2DD4, 0x44190B0D, 0x40D816BA,  //  88 [0x58 .. 0x5F]
    0xACA5C697, 0xA864DB20, 0xA527FDF9, 0xA1E6E04E, 0xBFA1B04B, 0xBB60ADFC, 0xB6238B25, 0xB2E29692,  //  96 [0x60 .. 0x67]
    0x8AAD2B2F, 0x8E6C3698, 0x832F1041, 0x87EE0DF6, 0x99A95DF3, 0x9D684044, 0x902B669D, 0x94EA7B2A,  // 104 [0x68 .. 0x6F]
    0xE0B41DE7, 0xE4750050, 0xE9362689, 0xEDF73B3E, 0xF3B06B3B, 0xF771768C, 0xFA325055, 0xFEF34DE2,  // 112 [0x70 .. 0x77]
    0xC6BCF05F, 0xC27DEDE8, 0xCF3ECB31, 0xCBFFD686, 0xD5B88683, 0xD1799B34, 0xDC3ABDED, 0xD8FBA05A,  // 120 [0x78 .. 0x7F]
    0x690CE0EE, 0x6DCDFD59, 0x608EDB80, 0x644FC637, 0x7A089632, 0x7EC98B85, 0x738AAD5C, 0x774BB0EB,  // 128 [0x80 .. 0x87]
    0x4F040D56, 0x4BC510E1, 0x46863638, 0x42472B8F, 0x5C007B8A, 0x58C1663D, 0x558240E4, 0x51435D53,  // 136 [0x88 .. 0x8F]
    0x251D3B9E, 0x21DC2629, 0x2C9F00F0, 0x285E1D47, 0x36194D42, 0x32D850F5, 0x3F9B762C, 0x3B5A6B9B,  // 144 [0x90 .. 0x97]
    0x0315D626, 0x07D4CB91, 0x0A97ED48, 0x0E56F0FF, 0x1011A0FA, 0x14D0BD4D, 0x19939B94, 0x1D528623,  // 152 [0x98 .. 0x9F]
    0xF12F560E, 0xF5EE4BB9, 0xF8AD6D60, 0xFC6C70D7, 0xE22B20D2, 0xE6EA3D65, 0xEBA91BBC, 0xEF68060B,  // 160 [0xA0 .. 0xA7]
    0xD727BBB6, 0xD3E6A601, 0xDEA580D8, 0xDA649D6F, 0xC423CD6A, 0xC0E2D0DD, 0xCDA1F604, 0xC960EBB3,  // 168 [0xA8 .. 0xAF]
    0xBD3E8D7E, 0xB9FF90C9, 0xB4BCB610, 0xB07DABA7, 0xAE3AFBA2, 0xAAFBE615, 0xA7B8C0CC, 0xA379DD7B,  // 176 [0xB0 .. 0xB7]
    0x9B3660C6, 0x9FF77D71, 0x92B45BA8, 0x9675461F, 0x8832161A, 0x8CF30BAD, 0x81B02D74, 0x857130C3,  // 184 [0xB8 .. 0xBF]
    0x5D8A9099, 0x594B8D2E, 0x5408ABF7, 0x50C9B640, 0x4E8EE645, 0x4A4FFBF2, 0x470CDD2B, 0x43CDC09C,  // 192 [0xC0 .. 0xC7]
    0x7B827D21, 0x7F436096, 0x7200464F, 0x76C15BF8, 0x68860BFD, 0x6C47164A, 0x61043093, 0x65C52D24,  // 200 [0xC8 .. 0xCF]
    0x119B4BE9, 0x155A565E, 0x18197087, 0x1CD86D30, 0x029F3D35, 0x065E2082, 0x0B1D065B, 0x0FDC1BEC,  // 208 [0xD0 .. 0xD7]
    0x3793A651, 0x3352BBE6, 0x3E119D3F, 0x3AD08088, 0x2497D08D, 0x2056CD3A, 0x2D15EBE3, 0x29D4F654,  // 216 [0xD8 .. 0xDF]
    0xC5A92679, 0xC1683BCE, 0xCC2B1D17, 0xC8EA00A0, 0xD6AD50A5, 0xD26C4D12, 0xDF2F6BCB, 0xDBEE767C,  // 224 [0xE0 .. 0xE7]
    0xE3A1CBC1, 0xE760D676, 0xEA23F0AF, 0xEEE2ED18, 0xF0A5BD1D, 0xF464A0AA, 0xF9278673, 0xFDE69BC4,  // 232 [0xE8 .. 0xEF]
    0x89B8FD09, 0x8D79E0BE, 0x803AC667, 0x84FBDBD0, 0x9ABC8BD5, 0x9E7D9662, 0x933EB0BB, 0x97FFAD0C,  // 240 [0xF0 .. 0xF7]
    0xAFB010B1, 0xAB710D06, 0xA6322BDF, 0xA2F33668, 0xBCB4666D, 0xB8757BDA, 0xB5365D03, 0xB1F740B4,  // 248 [0xF8 .. 0xFF]
};

const crc32_t host_crc32_table[CRC32_TABLE_SIZE] = {
    0x00000000, 0x04C11DB7, 0x09823B6E, 0x0D4326D9, 0x130476DC, 0x17C56B6B, 0x1A864DB2, 0x1E475005,  //   0 [0x00 .. 0x07]
    0x2608EDB8, 0x22C9F00F, 0x2F8AD6D6, 0x2B4BCB61, 0x350C9B64, 0x31CD86D3, 0x3C8EA00A, 0x384FBDBD,  //   8 [0x08 .. 0x0F]
    0x4C11DB70, 0x48D0C6C7, 0x4593E01E, 0x4152FDA9, 0x5F15ADAC, 0x5BD4B01B, 0x569796C2, 0x52568B75,  //  16 [0x10 .. 0x17]
    0x6A1936C8, 0x6ED82B7F, 0x639B0DA6, 0x675A1011, 0x791D4014, 0x7DDC5DA3, 0x709F7B7A, 0x745E66CD,  //  24 [0x18 .. 0x1F]
    0x9823B6E0, 0x9CE2AB57, 0x91A18D8E, 0x95609039, 0x8B27C03C, 0x8FE6DD8B, 0x82A5FB52, 0x8664E6E5,  //  32 [0x20 .. 0x27]
    0xBE2B5B58, 0xBAEA46EF, 0xB7A96036, 0xB3687D81, 0xAD2F2D84, 0xA9EE3033, 0xA4AD16EA, 0xA06C0B5D,  //  40 [0x28 .. 0x2F]
    0xD4326D90, 0xD0F37027, 0xDDB056FE, 0xD9714B49, 0xC7361B4C, 0xC3F706FB, 0xCEB42022, 0xCA753D95,  //  48 [0x30 .. 0x37]
    0xF23A8028, 0xF6FB9D9F, 0xFBB8BB46, 0xFF79A6F1, 0xE13EF6F4, 0xE5FFEB43, 0xE8BCCD9A, 0xEC7DD02D,  //  56 [0x38 .. 0x3F]
    0x34867077, 0x30476DC0, 0x3D044B19, 0x39C556AE, 0x278206AB, 0x23431B1C, 0x2E003DC5, 0x2AC12072,  //  64 [0x40 .. 0x47]
    0x128E9DCF, 0x164F8078, 0x1B0CA6A1, 0x1FCDBB16, 0x018AEB13, 0x054BF6A4, 0x0808D07D, 0x0CC9CDCA,  //  72 [0x48 .. 0x4F]
    0x7897AB07, 0x7C56B6B0, 0x71159069, 0x75D48DDE, 0x6B93DDDB, 0x6F52C06C, 0x6211E6B5, 0x66D0FB02,  //  80 [0x50 .. 0x57]
    0x5E9F46BF, 0x5A5E5B08, 0x571D7DD1, 0x53DC6066, 0x4D9B3063, 0x495A2DD4, 0x44190B0D, 0x40D816BA,  //  88 [0x58 .. 0x5F]
    0xACA5C697, 0xA864DB20, 0xA527FDF9, 0xA1E6E04E, 0xBFA1B04B, 0xBB60ADFC, 0xB6238B25, 0xB2E29692,  //  96 [0x60 .. 0x67]
    0x8AAD2B2F, 0x8E6C3698, 0x832F1041, 0x87EE0DF6, 0x99A95DF3, 0x9D684044, 0x902B669D, 0x94EA7B2A,  // 104 [0x68 .. 0x6F]
    0xE0B41DE7, 0xE4750050, 0xE9362689, 0xEDF73B3E, 0xF3B06B3B, 0xF771768C, 0xFA325055, 0xFEF34DE2,  // 112 [0x70 .. 0x77]
    0xC6BCF05F, 0xC27DEDE8, 0xCF3ECB31, 0xCBFFD686, 0xD5B88683, 0xD1799B34, 0xDC3ABDED, 0xD8FBA05A,  // 120 [0x78 .. 0x7F]
    0x690CE0EE, 0x6DCDFD59, 0x608EDB80, 0x644FC637, 0x7A089632, 0x7EC98B85, 0x738AAD5C, 0x774BB0EB,  // 128 [0x80 .. 0x87]
    0x4F040D56, 0x4BC510E1, 0x46863638, 0x42472B8F, 0x5C007B8A, 0x58C1663D, 0x558240E4, 0x51435D53,  // 136 [0x88 .. 0x8F]
    0x251D3B9E, 0x21DC2629, 0x2C9F00F0, 0x285E1D47, 0x36194D42, 0x32D850F5, 0x3F9B762C, 0x3B5A6B9B,  // 144 [0x90 .. 0x97]
    0x0315D626, 0x07D4CB91, 0x0A97ED48, 0x0E56F0FF, 0x1011A0FA, 0x14D0BD4D, 0x19939B94, 0x1D528623,  // 152 [0x98 .. 0x9F]
    0xF12F560E, 0xF5EE4BB9, 0xF8AD6D60, 0xFC6C70D7, 0xE22B20D2, 0xE6EA3D65, 0xEBA91BBC, 0xEF68060B,  // 160 [0xA0 .. 0xA7]
    0xD727BBB6, 0xD3E6A601, 0xDEA580D8, 0xDA649D6F, 0xC423CD6A, 0xC0E2D0DD, 0xCDA1F604, 0xC960EBB3,  // 168 [0xA8 .. 0xAF]
    0xBD3E8D7E, 0xB9FF90C9, 0xB4BCB610, 0xB07DABA7, 0xAE3AFBA2, 0xAAFBE615, 0xA7B8C0CC, 0xA379DD7B,  // 176 [0xB0 .. 0xB7]
    0x9B3660C6, 0x9FF77D71, 0x92B45BA8, 0x9675461F, 0x8832161A, 0x8CF30BAD, 0x81B02D74, 0x857130C3,  // 184 [0xB8 .. 0xBF]
    0x5D8A9099, 0x594B8D2E, 0x5408ABF7, 0x50C9B640, 0x4E8EE645, 0x4A4FFBF2, 0x470CDD2B, 0x43CDC09C,  // 192 [0xC0 .. 0xC7]
    0x7B827D21, 0x7F436096, 0x7200464F, 0x76C15BF8, 0x68860BFD, 0x6C47164A, 0x61043093, 0x65C52D24,  // 200 [0xC8 .. 0xCF]
    0x119B4BE9, 0x155A565E, 0x18197087, 0x1CD86D30, 0x029F3D35, 0x065E2082, 0x0B1D065B, 0x0FDC1BEC,  // 208 [0xD0 .. 0xD7]
    0x3793A651, 0x3352BBE6, 0x3E119D3F, 0x3AD08088, 0x2497D08D, 0x2056CD3A, 0x2D15EBE3, 0x29D4F654,  // 216 [0xD8 .. 0xDF]
    0xC5A92679, 0xC1683BCE, 0xCC2B1D17, 0xC8EA00A0, 0xD6AD50A5, 0xD26C4D12, 0xDF2F6BCB, 0xDBEE767C,  // 224 [0xE0 .. 0xE7]
    0xE3A1CBC1, 0xE760D676, 0xEA23F0AF, 0xEEE2ED18, 0xF0A5BD1D, 0xF464A0AA, 0xF9278673, 0xFDE69BC4,  // 232 [0xE8 .. 0xEF]
    0x89B8FD09, 0x8D79E0BE, 0x803AC667, 0x84FBDBD0, 0x9ABC8BD5, 0x9E7D9662, 0x933EB0BB, 0x97FFAD0C,  // 240 [0xF0 .. 0xF7]
    0xAFB010B1, 0xAB710D06, 0xA6322BDF, 0xA2F33668, 0xBCB4666D, 0xB8757BDA, 0xB5365D03, 0xB1F740B4,  // 248 [0xF8 .. 0xFF]
};

__device__
std::uint32_t crc32(const char* str, std::uint32_t value = 0)
{
    while (*str != '\0')
    {
        value = (value >> 8) ^ crc32_table[(*str ^ value) & 0xff];
        ++str;
    }

    return value;
}

__host__
std::uint32_t hostCRC32(const char* str, std::uint32_t value = 0)
{
    while (*str != '\0')
    {
        value = (value >> 8) ^ host_crc32_table[(*str ^ value) & 0xff];
        ++str;
    }

    return value;
}

#define BLOCK_MAX (64U)
#define THREAD_MAX (1024U)

#define CHARS_LEN (40U)
__constant__ char CHARS[CHARS_LEN + 1] = "-.0123456789>_abcdefghijklmnopqrstuvwxyz";

#define MAX_DIRECTORIES (1U)

struct trace_t
{
    std::uint32_t data[MAX_DIRECTORIES] = { 0 };
};

__device__
bool search(crc32_t hash)
{
    std::uint64_t low = 0;
    std::uint64_t high = HASHES_LEN - 1;
    std::uint64_t middle = low + ((high - low) / 2);  // prevents overflow related errors https://ai.googleblog.com/2006/06/extra-extra-read-all-about-it-nearly.html

    do
    {
        if (HASHES[middle] < hash)
        {
            low = middle + 1;
        }
        else if (HASHES[middle] > hash)
        {
            high = middle - 1;
        }
        else
        {
            return true;
        }

        middle = low + ((high - low) / 2);
    } while (low < high && middle > 0);

    if (HASHES[low] == hash)
    {
        return true;
    }

    return false;
}

__global__
void kernel(std::uint32_t offset, crc32_t hash, std::uint32_t depth, trace_t trace)
{
    std::uint32_t id = blockIdx.x * THREAD_MAX + threadIdx.x + offset;

    if (id >= DICTIONARY_LEN)
    {
        return;
    }

    hash = crc32(DICTIONARY[id], hash);
    if (search(hash))
    {
        switch (depth)
        {
        case 0:
            printf("%u = db:>%s\n", hash, DICTIONARY[id]);
            break;
        case 1:
            printf("%u = db:>%s>%s\n", hash, DICTIONARY[trace.data[0]], DICTIONARY[id]);
            break;
        case 2:
            printf("%u = db:>%s>%s>%s\n", hash, DICTIONARY[trace.data[0]], DICTIONARY[trace.data[1]], DICTIONARY[id]);
            break;
        case 3:
            printf("%u = db:>%s>%s>%s>%s\n", hash, DICTIONARY[trace.data[0]], DICTIONARY[trace.data[1]], DICTIONARY[trace.data[2]], DICTIONARY[id]);
            break;
        case 4:
            printf("%u = db:>%s>%s>%s>%s>%s\n", hash, DICTIONARY[trace.data[0]], DICTIONARY[trace.data[1]], DICTIONARY[trace.data[2]], DICTIONARY[trace.data[3]], DICTIONARY[id]);
            break;
        default:
            break;
        }
    }

    if (depth < MAX_DIRECTORIES)
    {
        trace.data[depth] = id;
        hash = (hash >> 8) ^ crc32_table[('>' ^ hash) & 0xff];
        for (std::uint32_t i = 0; i < ((DICTIONARY_LEN / BLOCK_MAX) / THREAD_MAX) + 1; ++i)
        {
            kernel << <BLOCK_MAX, THREAD_MAX >> > (i * BLOCK_MAX * THREAD_MAX, hash, depth + 1, trace);
        }
    }
}

int main()
{
    FILE* f = fopen("reduced.dict", "rb");
    if (!f)
    {
        return 1;
    }
    std::uint64_t size;
    fread(&size, sizeof(size), 1, f);
    CUDA_ASSERT(cudaMemcpyToSymbol(DICTIONARY_LEN, &size, sizeof(size)));

    fseek(f, 0L, SEEK_END);
    unsigned long bufferSize = ftell(f) - sizeof(size);
    fseek(f, (unsigned long)sizeof(size), SEEK_SET);

    std::uint64_t *hostDictionary = (std::uint64_t*)malloc(bufferSize);
    if (!hostDictionary)
    {
        return 3;
    }
    fread(hostDictionary, sizeof(std::uint8_t), bufferSize, f);
    fclose(f);
    f = nullptr;
    char** deviceDictionary;
    CUDA_ASSERT(cudaMalloc((void**)&deviceDictionary, bufferSize));

    for (std::uint64_t i = 0; i < size; ++i)
    {
        hostDictionary[i] += (std::uint64_t)deviceDictionary;
    }

    CUDA_ASSERT(cudaMemcpy(deviceDictionary, hostDictionary, bufferSize, cudaMemcpyHostToDevice));
    CUDA_ASSERT(cudaMemcpyToSymbol(DICTIONARY, &deviceDictionary, sizeof(deviceDictionary)));

    free(hostDictionary);
    hostDictionary = nullptr;

    f = fopen("reduced.hash", "rb");
    std::uint64_t hashesLen;
    fread(&hashesLen, sizeof(hashesLen), 1, f);
    CUDA_ASSERT(cudaMemcpyToSymbol(HASHES_LEN, &hashesLen, sizeof(hashesLen)));

    crc32_t* hostHashes = (crc32_t*)malloc(hashesLen * sizeof(crc32_t));
    if (!hostHashes)
    {
        return 4;
    }

    for (std::uint64_t i = 0; i < hashesLen; ++i)
    {
        fread(hostHashes, sizeof(crc32_t), hashesLen, f);
    }

    fclose(f);
    f = nullptr;

    crc32_t* deviceHashes;
    CUDA_ASSERT(cudaMalloc((void**)&deviceHashes, hashesLen * sizeof(crc32_t)));
    CUDA_ASSERT(cudaMemcpy(deviceHashes, hostHashes, hashesLen * sizeof(crc32_t), cudaMemcpyHostToDevice));
    CUDA_ASSERT(cudaMemcpyToSymbol(HASHES, &deviceHashes, sizeof(deviceHashes)));

    const std::uint32_t INITIAL_CRC32 = hostCRC32("db:>");
    trace_t trace = { 0 };
    for (std::uint32_t i = 0; i < ((size / BLOCK_MAX) / THREAD_MAX) + 1; ++i)
    {
        kernel << <BLOCK_MAX, THREAD_MAX >> > (i * BLOCK_MAX * THREAD_MAX, INITIAL_CRC32, 0, trace);
    }
    CUDA_ASSERT(cudaPeekAtLastError());
    CUDA_ASSERT(cudaDeviceSynchronize());
    cudaDeviceReset();
    return 0;
}
