#include <fstream>
#include <unordered_set>
#include <string>

int main()
{
	std::ifstream in("reduced.txt");
	if (!in.good()) return 1;

	std::unordered_set<std::string> dictionary;
	std::string line;
	while (!std::getline(in, line).eof())
	{
		dictionary.insert(line);
	}

	in.close();

	std::ofstream out("reduced.dict", std::ios::binary);
	if (!out.good()) return 2;

	std::uint64_t size = dictionary.size();
	out.write(reinterpret_cast<char*>(&size), sizeof(size));
	size = dictionary.size() * sizeof(size);
	for (const std::string& str : dictionary)
	{
		out.write((const char*)&size, sizeof(size));
		size += str.length() + 1;
	}
	for (const std::string& str : dictionary)
	{
		out.write(str.c_str(), str.length() + 1);
	}

	out.close();

	return 0;
}
