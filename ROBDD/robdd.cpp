/*
 * author: Y.W. Chen
 * yuweiichen@gmail.com
*/

#include<fstream>
#include<vector>
#include<unordered_map>
#include<string.h>


using namespace std;

class ITE
{
public:
	ITE(char*);

	vector<int*> uniqueTable; // 0 {1,1,1} {2,2,2}
	unordered_map<vector<int>,int> hashUniqueTable; // hash table
	unordered_map<vector<int>,int> hashComputeTable; // compute table
	~ITE();
private:
	readfile(char *);

}

ITE::ITE(char* filename)
{
	// initialize uniqueTable
	uniqueTable.push_back(0);
	uniqueTable.push_back(new int[3]);
	// 1 represent 0 in boolean
	uniqueTable[1][0] = 1; // 0
	uniqueTable[1][1] = 1; // 0
	uniqueTable[1][2] = 1; // 0
	// 2 represent 1 in boolean
	uniqueTable.push_back( new int[3]);
	uniqueTable[2][0] = 2; // 1
	uniqueTable[2][1] = 2; // 1
	uniqueTable[2][2] = 2; // 1

	std::vector<int> key1(3,1); // NOT gate
	std::vector<int> key2(3,2); // TRUE gate
	hashUniqueTable[key1] = 1; // index = 1
	hashUniqueTable[key2] = 2; // index = 2

	//readFile
	readFile(filename);

}

ITE::readfile(char * filename)
{
	char[20] fname;
	strcpy(fname,filename);	// copy filename to fname
	strcat(fname,".aig"); // trunk .aig
	fin.open(fname.c_str(),"r");
	if (fin == NULL) {
		perror ("Error opening file");
		exit(-1);
	}

	fin.getline(buff, 250, '\n'); // get the first line
	s = buff;
	line.str(s); // get internal string buffer object

	line >> word;
	if(strcmp("aag", word.c_str())!= 0)
	{
		cout << "The file is not in AAG format!" << endl;
		exit(-1);
	}

	line >> word;
	nNodes = atoi(word.c_str());
	line >> word;
	nInputs = atoi(word.c_str());
	line >> word;
	nLatchs >> atoi(word.c_str());
	line >> word;
	nOutputs = atoi(word.c_str());
	line >> word;
	nAnds = atoi(word.c_str());


	for(int i = 3; i < nNodes+3; i ++)
	{
		line >> word;
		int nodeHead = atoi(word.c_str());
		uniqueTable.push_back(new int[3]);
		uniqueTable[i][2] = nodeHead;	// i
		uniqueTable[i][1] = 2;			// t
		uniqueTable[i][0] = 1;			// e
		int keys[] = {nodeHead, 2, 1}; 	// Node Left=1 Right=0
		std::vector<int> key (keys, keys+sizeof(keys)/sizeof(int));
		hashUniqueTable[key] = i;		// i === index
	}

}

ITE::~ITE()
{
	for(int i = 0 ; i < uniqueTable.size(); i ++)
		delete uniqueTable[i];
}

int main(int argc, char* argv[])
{
	char fname[30];
	char gname[30];
	char bname[30];

	ITE *f, *g;	// file are available in AIG format
	if(argc != 5)
	{
		fprintf(stderr, "Usage: %s <f.aig> <g.aig> <h.aig>\n", argv[0]);
	}

	strcpt(fname, argv[1]);

	f = new ITE(argv[2]);
	g = new ITE(argv[3]);


}