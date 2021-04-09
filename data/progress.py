import csv

total = 0
totalSolved = 0

dictionaryTotal = {}
dictionaryTotalSolved = {}

dpcTotal = {}
dpcSolved = {}

with open('crc32s.txt') as csvfile:
    spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
    for row in spamreader:
		if row[2] not in dictionaryTotal:
			dictionaryTotal[row[2]] = 0
			dictionaryTotalSolved[row[2]] = 0
		for dpc in row[3].split(' '):
			if dpc not in dpcTotal:
				dpcTotal[dpc] = 0
				dpcSolved[dpc] = 0
			dpcTotal[dpc] += 1
		dictionaryTotal[row[2]] += 1
		total += 1
		if len(row[4]):
			for dpc in row[3].split(' '):
				dpcSolved[dpc] += 1
			dictionaryTotalSolved[row[2]] += 1
			totalSolved += 1

for key in dictionaryTotal:
	print('{}: {}/{} {:.2%}'.format(key, dictionaryTotalSolved[key], dictionaryTotal[key], float(dictionaryTotalSolved[key]) / dictionaryTotal[key]))

print('\n')

for key in dpcTotal:
	print('{}: {}/{} {:.2%}'.format(key, dpcSolved[key], dpcTotal[key], float(dpcSolved[key]) / dpcTotal[key]))

print('\nTotal: {}/{} {:.2%}'.format(totalSolved, total, float(totalSolved) / total))
