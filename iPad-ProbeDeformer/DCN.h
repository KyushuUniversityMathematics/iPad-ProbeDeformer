//
//  DCN.h
//

#ifndef ProbeDeformer_DCN_h
#define ProbeDeformer_DCN_h

#include <iostream>
#include <math.h>

using namespace std;

template <class T>
class DCN{
public:
    T real[2];
    T dual[2];
    // constructor
    DCN(){ real[0]=0; real[1]=0; dual[0]=0; dual[1]=0;}
	DCN(T a_real0, T a_real1, T a_dual0, T a_dual1){
        real[0] = a_real0;
        real[1] = a_real1;
        dual[0] = a_dual0;
        dual[1] = a_dual1;
    }
    DCN(T x, T y, T theta){    // rotation centered at (x,y)
        DCN v(cos(theta/2.0),sin(theta/2.0),0,0);
        DCN u(1,0,-x/2.0,-y/2.0);
        DCN w(1,0,x/2.0,y/2.0);
        DCN result = w*v*u;
        real[0] = result.real[0];
        real[1] = result.real[1];
        dual[0] = result.dual[0];
        dual[1] = result.dual[1];
    }
//functions
	void print(){
		std::cout << real[0] << "+" << real[1] <<  " i + (" << dual[0] << "+" << dual[1] << "i)e" << std::endl;
	}
    DCN conj(){
        DCN result;
        result.real[0] = real[0];
        result.real[1] = -real[1];
        result.dual[0] = dual[0];
        result.dual[1] = dual[1];
        return result;
    }
    DCN actedby(DCN dcn){
        DCN result;
        result.real[0] = 1;
        result.real[1] = 0;
        result.dual[0] = (dcn.real[0]*dcn.real[0]-dcn.real[1]*dcn.real[1])*dual[0]
        +2*(dcn.real[0]*dcn.dual[0] - dcn.real[1]*dcn.dual[1]-dcn.real[0]*dcn.real[1]*dual[1]);
        result.dual[1] = (dcn.real[0]*dcn.real[0]-dcn.real[1]*dcn.real[1])*dual[1]
            +2*(dcn.real[0]*dcn.real[1]*dual[0] + dcn.real[0]*dcn.dual[1] + dcn.real[1]*dcn.dual[0]);
        return result;
    }
    DCN normalised(){
        DCN result;
        T norm = sqrt(real[0]*real[0]+real[1]*real[1]);
        result.real[0] = real[0]/norm;
        result.real[1] = real[1]/norm;
        result.dual[0] = dual[0]/norm;
        result.dual[1] = dual[1]/norm;
        return result;
    }
    T norm(){
        return(sqrt(real[0]*real[0]+real[1]*real[1]));
    }
    // operations
    void operator*=(T scale){
        real[0] *= scale; real[1] *= scale; dual[0] *= scale; dual[1] *= scale;
        return *this;
    }
    void operator+=(DCN toSum){
        real[0] += toSum.real[0];
        real[1] += toSum.real[1];
        dual[0] += toSum.dual[0];
        dual[1] += toSum.dual[1];
    }
    DCN operator *(T scale){
        DCN result;
        result.real[0] = real[0]*scale;
        result.real[1] = real[1]*scale;
        result.dual[0] = dual[0]*scale;
        result.dual[1] = dual[1]*scale;
        return result;
    }
    void operator =(DCN dcn){
        real[0] = dcn.real[0];
        real[1] = dcn.real[1];
        dual[0] = dcn.dual[0];
        dual[1] = dcn.dual[1];
    }
    DCN operator *(DCN dcn){
        DCN result;
        result.real[0] = real[0]*dcn.real[0]-real[1]*dcn.real[1];
        result.real[1] = real[0]*dcn.real[1]+real[1]*dcn.real[0];
        result.dual[0] = real[0]*dcn.dual[0]-real[1]*dcn.dual[1]+dual[0]*dcn.real[0]+dual[1]*dcn.real[1];
        result.dual[1] = real[0]*dcn.dual[1]+real[1]*dcn.dual[0]-dual[0]*dcn.real[1]+dual[1]*dcn.real[0];
        return result;
    }
    DCN operator +(DCN dcn){
        DCN result;
        result.real[0] = real[0]+dcn.real[0];
        result.real[1] = real[1]+dcn.real[1];
        result.dual[0] = dual[0]+dcn.dual[0];
        result.dual[1] = dual[1]+dcn.dual[1];
        return result;
    }
private:
};

#endif
