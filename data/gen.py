with open('meshes.txt','r') as file:
	for line in file:
		line = line.strip()
		print(line + "_BF_PARTICLESDATA_0")
