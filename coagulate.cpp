#include <fstream>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <string>
#include <sstream>
#include <iostream>

typedef std::uint32_t crc32_t;

int main()
{
	std::string beginning = "db:>textures>fxs>";

	std::ifstream resultsFile("out.txt");
	std::ifstream hashesFile("hashes.cog");
	std::ifstream dictionaryFile("dictionary.cog");

	struct HashPair
	{
		crc32_t hash;
		std::string ext;
	};
	std::unordered_map<crc32_t, std::vector<HashPair>> hashes;

	crc32_t hash;
	crc32_t temp;
	std::string str;
	while (hashesFile >> temp >> hash >> str)
	{
		hashes[hash].push_back({temp, str});
	}

	std::unordered_map<crc32_t, std::vector<std::string>> dictionary;
	while (dictionaryFile >> hash >> str)
	{
		dictionary[hash].push_back(str);
	}

	while (std::getline(resultsFile, str))
	{
		std::stringstream ss(str);

		ss >> hash;
		std::vector<HashPair> hp = hashes[hash];

		std::cout << beginning;

		ss >> hash;
		while (true)
		{
			std::cout << dictionary[hash][0];

			if (ss >> hash)
			{
				std::cout << ">";
			}
			else
			{
				break;
			}
		}

		std::cout << hp[0].ext << " = " << hp[0].hash << "\n";
	}
}
