#include <iostream>
#include <fstream>
#include <unordered_map>
#include <vector>

using namespace std;

class ITE
{
private:
	string s, line;
	char buff[250], word[8];
	int nNodes, nInputs, nLatchs, nOutputs, nAnds;
	istringstream line;
	FILE* fin;
	std::vector<int> gateNode; // default 0
	std::vector<int*> uniqueTable; // 0 {1,1,1} {2,2,2}
	unordered_map<vector<int>,int> hashUniqueTable; // hash table
	unordered_map<vector<int>,int> hashComputeTable; // compute table
public:
	ITE(char * filename);
	~ITE();
	void getBDD(void);
	void readFile(char * filename);
	int ite(int i, int j, int k);
	bool terminal(int i,int t,int e,int& terminalResult);
	bool isExists(int f,int g,int h,int& index);
	int findorAddUniqueTable(int top, int t, int e);
	int topVariable(int i, int t, int e);
	int function(int head, int top, bool tf);	
};

// ITE Class constructor
ITE::ITE(char * filename)
{
	// initialize uniqueTable
	uniqueTable.push_back(0);
	uniqueTable.push_back(new int[3]);
	// 1 represent 0 in boolean
	uniqueTable[1][2] = 1; // 0 I
	uniqueTable[1][1] = 1; // 0 T
	uniqueTable[1][0] = 1; // 0 E
	// 2 represent 1 in boolean
	uniqueTable.push_back( new int[3]);
	uniqueTable[2][2] = 2; // 1 I
	uniqueTable[2][1] = 2; // 1 T
	uniqueTable[2][0] = 2; // 1 E

	std::vector<int> key1(3,1); // NOT gate
	std::vector<int> key2(3,2); // TRUE gate
	hashUniqueTable[key1] = 1; // index = 1
	hashUniqueTable[key2] = 2; // index = 2

	//readFile
	readFile(filename);
}

int ITE::ite(int i, int j, int k)
{
	int terminalResult = 0;
	// Check if the ITE is the terminal case
	if(terminal(i,t,e,terminalResult))
		return terminalResult
	else{
		if(isExists(i,t,e,terminalResult)){
			return terminalResult;
		}else{
			int top = topVariable(i,t,e);
			int t = ite(function(i,top,true), function(t,top,true),function(e,top,true));
			int e = ite(function(i,top,false), function(t,top,false), function(e,top,true));

			if(t == e)
				return t;

			int r = findorAddUniqueTable(top,t,e);

			int keys[] = {i,t,e};
			std::vector<int> key (keys, keys+sizeof(keys)/sizeof(int));
			hashComputeTable[key] = r;

			return r;
		}
	}
}

// find / insert uniqueTable
int ITE::findorAddUniqueTable(int top, int t, int e)
{
	int key[] = {top, t, e};
	std::vector<int> key ( keys, keys+ sizeof(keys)/sizeof(int));

	// Check if the uniqueTable exist already
	if(hashUniqueTable.find(key) != hashUniqueTable.end())
		return hashUniqueTable[key];

	// Add ite into hashUniqueTable
	int index = uniqueTable.size();

	uniqueTable.push_back(new int[3]);
	uniqueTable[index][2] = i;
	uniqueTable[index][1] = t;
	uniqueTable[index][0] = e;

	hashUniqueTable[key] = index;

	return index;
}

int ITE::topVariable(int i, int t, int e)
{
	int min = i;

	if(t < min)
		min = t;
	
	if(e < min)
		min = e;
	
	return min;	// the minimal value is the top Node
}

// function
int ITE::function(int head, int top, bool tf)
{
	// Check the head is possitive or negetive
	if(head%2 == 0){
		// Terminal Nodes
		if(head == 1 || head == 2)
			return head;

		//Return node
		if(uniqueTable[head][2] == top && tf)
			return uniqueTable[head][1];
		else if(uniqueTable[head][2] == top && !tf)
			return uniqueTable[head][0];

		return head;
	}else{
		if(head == 2)
			return 1;
		else if(head == 1)
			return 2;

		if(uniqueTable[head][2] == top && tf)
			return uniqueTable[head][0];
		else if(uniqueTable[head][2]== top && !tf)
			return uniqueTable[head][1];

		return head -1;
	}
}

// The Terminal Case
bool ITE::terminal(int i, int t, int e, int& terminalResult)
{
	if(i == 2) // if  I == 1
		terminalResult = t; // return true
	else if(i == 1) // if I == 0
		terminalResult = e;
	else if(t == 2 && e == 1) // T == 1 and E == 0
		terminalResult = i;
	else if(t == e) // T == E
		terminalResult = t;
	else if(t == 1 && e == 2)
		terminalResult = -1 * i;
	else
		return false;

	return true;
}

// Check the computed table has entry {(f,g,h),r}
bool ITE::isExists(int f, int g, int h, int& computedTableIndex)
{	
	// Key
	int keys[] = {f,g,h};
	std::vector<int> key(keys, keys+sizeof(keys)/sizeof(int));

	// Check Computed Table
	if(computeTable.find(key) == computeTable.end()) // can't find the index for ITE
		return false;
	else{
		computedTableIndex = computeTable[key];
		return true;
	}
}

void ITE::readFile(char * filename)
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
		fin.getline(buff, 250, '\n'); // get the first line
		s = buff;
		line.str(s);
		line >> word;
		uniqueTable.push_back(new int[3]);
		uniqueTable[i][2] = atoi(word.c_str());	// i
		uniqueTable[i][1] = 2;					// t
		uniqueTable[i][0] = 1;					// e

		int keys[] = {atoi(word.c_str()), 2, 1}; // Node Left=1 Right=0
		std::vector<int> key (keys, keys+sizeof(keys)/sizeof(int));
		hashUniqueTable[key] = i;		// i === index
		gateNode.push_back(i);
	}
}

ITE::~ITE()
{
	//delete uniqueTable
	for(int i= 0 ; i < uniqueTable.size(); i ++)
		delete uniqueTable[i];
}

void ITE::getBDD(void)
{
	for(int i =0; i < nAnds; i++)
	{
		int index;
		int head;
		int i, t, e;
		fin.getline(buff, 250, '\n'); // get the first line
		s = buff;
		line.str(s);
		line >> word;
		if(atoi(word.c_str()) %2 == 0){
			// AND node
			line >> word;
			head = atoi(word.c_str());
			if(head %2 != 0){
				head -= 1;
				i = -(head)
			}
			index = ite()
		}else{
			// NAND node
		}

		gateNode.push_back(index);
	}
}

int main(int argc, char *argv[])
{
	if(argc != 5)
	{
		fprintf("The run method is ./%s [input1] [input2] [input3] [output]", argv[0] );
		return 0;	
	}
	ITE f = ITE(argv[1]);
	ITE g = ITE(argv[2]);

	// Function reader haven't finished

	return 0;
}

