/**
 * @file    Library for Dual Complex Numbers
 * @author  Shizuo KAJI <shizuo.kaji@gmail.com>
 * @version 0.10 Mar.2014
 *
 * @section LICENSE The MIT License
 * @section DESCRIPTION
 * Library for Anti-commutative Dual Complex Numbers (DCN, for short)
 * For the detail, look at
 * G. Matsuda, S. Kaji, and H. Ochiai, Anti-commutative Dual Complex Numbers and 2D Rigid Transformation,
 * Mathematical Progress in Expressive Image Synthesis I, Springer-Japan, 2014.
*/

#pragma once

#include <iostream>
#include <math.h>
#include <vector>

using namespace std;

template <class T>

class DCN{
public:
    /// coordinates which is the real part of the DCN
    T real[2];
    /// coordinates which is the complex part of the DCN
    T dual[2];
    /// constructor
    DCN(){ real[0]=0; real[1]=0; dual[0]=0; dual[1]=0;}
    /** Constructor that creats DCN with given real and dual parts
     @param a_real0 the x-coordinate of the real part
     @param a_real1 the y-coordinate of the real part
     @param a_dual0 the x-coordinate of the dual part
     @param a_dual1 the y-coordinate of the dual part
     */
	DCN(T a_real0, T a_real1, T a_dual0, T a_dual1){
        real[0] = a_real0;
        real[1] = a_real1;
        dual[0] = a_dual0;
        dual[1] = a_dual1;
    }
    /** Constructor that creats DCN which represents the rotation around a given point
     @param x the x-coordinate of the center of the rotation
     @param x the y-coordinate of the center of the rotation
     @param theta the degree in radian of the rotation
     */
    DCN(T x, T y, T theta){
        DCN v(cos(theta/2.0),sin(theta/2.0),0,0);
        DCN u(1,0,-x/2.0,-y/2.0);
        DCN w(1,0,x/2.0,y/2.0);
        DCN result = w*v*u;
        real[0] = result.real[0];
        real[1] = result.real[1];
        dual[0] = result.dual[0];
        dual[1] = result.dual[1];
    }
    /// print the contents of the DCN in a human readable form to stdout
	void print(){
		std::cout << real[0] << "+" << real[1] <<  " i + (" << dual[0] << "+" << dual[1] << "i)e" << std::endl;
	}
    /// conjugation
    /// @return the conjugate of the DCN
    DCN conj(){
        DCN result;
        result.real[0] = real[0];
        result.real[1] = -real[1];
        result.dual[0] = dual[0];
        result.dual[1] = dual[1];
        return result;
    }
    /** action
     @param dcn DCN which acts
     @return the resulting DCN acted by dcn
    */
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
    /** normalisation to unit length DCN
     @return DCN the unit length DCN
     */
    DCN normalised(){
        DCN result;
        T norm = sqrt(real[0]*real[0]+real[1]*real[1]);
        result.real[0] = real[0]/norm;
        result.real[1] = real[1]/norm;
        result.dual[0] = dual[0]/norm;
        result.dual[1] = dual[1]/norm;
        return result;
    }
    /** norm
     @return norm of the DCN
     */
    T norm(){
        return(sqrt(real[0]*real[0]+real[1]*real[1]));
    }
    /// multiplication by a scalar
    void operator*=(T scale){
        real[0] *= scale; real[1] *= scale; dual[0] *= scale; dual[1] *= scale;
        return *this;
    }
    /// sum
    void operator+=(DCN toSum){
        real[0] += toSum.real[0];
        real[1] += toSum.real[1];
        dual[0] += toSum.dual[0];
        dual[1] += toSum.dual[1];
    }
    /// multiplication by a scalar
    DCN operator *(T scale){
        DCN result;
        result.real[0] = real[0]*scale;
        result.real[1] = real[1]*scale;
        result.dual[0] = dual[0]*scale;
        result.dual[1] = dual[1]*scale;
        return result;
    }
    /// substitution
    void operator =(DCN dcn){
        real[0] = dcn.real[0];
        real[1] = dcn.real[1];
        dual[0] = dcn.dual[0];
        dual[1] = dcn.dual[1];
    }
    /// multiplication by a DCN
    DCN operator *(DCN dcn){
        DCN result;
        result.real[0] = real[0]*dcn.real[0]-real[1]*dcn.real[1];
        result.real[1] = real[0]*dcn.real[1]+real[1]*dcn.real[0];
        result.dual[0] = real[0]*dcn.dual[0]-real[1]*dcn.dual[1]+dual[0]*dcn.real[0]+dual[1]*dcn.real[1];
        result.dual[1] = real[0]*dcn.dual[1]+real[1]*dcn.dual[0]-dual[0]*dcn.real[1]+dual[1]*dcn.real[0];
        return result;
    }
    /// sum
    DCN operator +(DCN dcn){
        DCN result;
        result.real[0] = real[0]+dcn.real[0];
        result.real[1] = real[1]+dcn.real[1];
        result.dual[0] = dual[0]+dcn.dual[0];
        result.dual[1] = dual[1]+dcn.dual[1];
        return result;
    }
    /** linear blend (DLB)
     @param dcns array of DCN's to be blended
     @param weights weights of the correspoding DCN's
     @return blended normalised DCN
     */
    DCN blend (std::vector<DCN> dcns, std::vector<T> weights){
        assert(dcns.size() == weights.size());
        DCN result;
        for(int i=0;i<dcns.size();i++){
            result += dcns[i] * weights[i];
        }
        return(result.normalised());
    }

private:
};
