class model_comparator{
private:
public:
	// constructor
	model_comparator(){}
	// methods
	int process(int a, int b){
		if (a == b) 	return 1;
		else 		return 0;
	}
};

// class static wrapper
// --------------------------------------------------------------------
#ifdef __cplusplus
extern "C" {
#endif

void *pGetModelHandle(){
	return ((void *)new model_comparator);
};

int getModelResult(void *pHandle, int value0, int value1){
	return ((model_comparator *)pHandle)->process(value0, value1);
};

#ifdef __cplusplus
}
#endif