
#include <math.h>

//====================================================================
//============ Kernels Section ======================================= 
//====================================================================

__device__ void count123(double *XXX, PointW3D *elements, int start1, int end1, int start2, int end2, int start3, int end3, int bn, double ds, float dd_max, float size_box, bool fx_2, bool fy_2, bool fz_2, bool fx_3, bool fy_3, bool fz_3, int bn_offset=0){
    /*
    Device function only callable from GPU.

    Given that three nodes are closer to each other than the maximum distance this function counts all the possible triangles 
    with one point in each node. If the triangles within one nodes are required simply pass the same node three times. This 
    function can compute the trieangles from nodes where one or two of the nodes are proyected to a boundary. It considers 
    only one kind of nodes, either data nodes or random nodes but not both.

    args:
    XXX: (double*) The histogram where the distances are counted.
    elements: (PointW3D*) Array of the points ordered coherently with the nodes.
    start1: (int) Index where the points of the node 1 start. Locatedin the elements array.
    end1: (int) Index where the points of the node 1 end. Locatedin the elements array.
    start2: (int) Index where the points of the node 2 start. Locatedin the elements array.
    end2: (int) Index where the points of the node 2 end. Locatedin the elements array.
    start3: (int) Index where the points of the node 3 start. Locatedin the elements array.
    end3: (int) Index where the points of the node 3 end. Locatedin the elements array.
    bn: (int) NUmber of bins in the XY histogram.
    ds: (double) Constant to calculate the bin index where the triangle count will be stored.
    ddmax: (float) The square of the maximum distance of interest between points.
    size_box: (float) The size of the box where the points were contained. It is used to calculate the proyected nodes.
    fx_2: (bool) True if the node number 2 is proyected in the x direction.
    fy_2: (bool) True if the node number 2 is proyected in the y direction.
    fz_2: (bool) True if the node number 2 is proyected in the z direction.
    fx_3: (bool) True if the node number 3 is proyected in the x direction.
    fy_3: (bool) True if the node number 3 is proyected in the y direction.
    fz_3: (bool) True if the node number 3 is proyected in the z direction.
    bn_offset: (int) Number of randomfile if there are many random files
    */

    int bnx, bny, bnz, bin;
    float x1,y1,z1,w1,x2,y2,z2,w2,x3,y3,z3;
    float dx12, dy12, dz12, dx23, dy23, dz23, dx31, dy31, dz31;
    double d12,d23,d31;
    double v;

    for (int i=start1; i<end1; i++){
        //Node 1 is never proyected
        x1 = elements[i].x;
        y1 = elements[i].y;
        z1 = elements[i].z;
        w1 = elements[i].w;
        for (int j=start2; j<end2; j++){
            x2 = elements[j].x;
            y2 = elements[j].y;
            z2 = elements[j].z;
            w2 = elements[j].w;
            dx12 = fabsf(x2-x1) - size_box*fx_2;
            dy12 = fabsf(y2-y1) - size_box*fy_2;
            dz12 = fabsf(z2-z1) - size_box*fz_2;
            d12 = dx12*dx12 + dy12*dy12 + dz12*dz12;
            if (d12 < dd_max && d12>0){
                v = w1*w2;
                d12 = sqrt(d12);
                for (int k=start3; k<end3; k++){
                    x3 = elements[k].x;
                    y3 = elements[k].y;
                    z3 = elements[k].z;
                    dx23 = fabsf(x3-x2) - fabsf(size_box*fx_2 - size_box*fx_3);
                    dy23 = fabsf(y3-y2) - fabsf(size_box*fy_2 - size_box*fy_3);
                    dz23 = fabsf(z3-z2) - fabsf(size_box*fz_2 - size_box*fz_3);
                    d23 = dx23*dx23 + dy23*dy23 + dz23*dz23;
                    if (d23 < dd_max && d23>0){
                        dx31 = fabsf(x3-x1) - size_box*fx_3;
                        dy31 = fabsf(y3-y1) - size_box*fy_3;
                        dz31 = fabsf(z3-z1) - size_box*fz_3;
                        d31 = dx31*dx31 + dy31*dy31 + dz31*dz31;
                        if (d31 < dd_max && d31>0){
                            d23 = sqrt(d23);
                            d31 = sqrt(d31);

                            bnx = (int)(d12*ds)*bn*bn;
                            if (bnx>(bn*bn*(bn-1))) continue;
                            bny = (int)(d23*ds)*bn;
                            if (bny>(bn*(bn-1))) continue;
                            bnz = (int)(d31*ds);
                            if (bnz>(bn-1)) continue;
                            bin = bnx + bny + bnz;
                            bin += bn_offset*bn*bn*bn;
                            v *= elements[k].w;
                            
                            atomicAdd(&XXX[bin],v);
                        }
                    }
                }
            }
        }
    }
}
__device__ void count123_mixed(double *XXY, PointW3D *elementsX, PointW3D *elementsY, int start1, int end1, int start2, int end2, int start3, int end3, int bn, double ds, float dd_max, float size_box, bool fx_2, bool fy_2, bool fz_2, bool fx_3, bool fy_3, bool fz_3, int bn_offset=0){
    /*
    Device function only callable from GPU.

    Given that three nodes are closer to each other than the maximum distance this function counts all the possible triangles 
    with one point in each node. If the triangles within one nodes are required simply pass the same node three times. This 
    function can compute the trieangles from nodes where one or two of the nodes are proyected to a boundary. It considers 
    only one kind of nodes, either data nodes or random nodes but not both.

    args:
    XXY: (double*) The histogram where the distances are counted.
    elementsX: (PointW3D*) Array of the points ordered coherently with the X nodes.
    elementsY: (PointW3D*) Array of the points ordered coherently with the Y nodes.
    start1: (int) Index where the points of the node 1 start. Locatedin the elements array.
    end1: (int) Index where the points of the node 1 end. Locatedin the elements array.
    start2: (int) Index where the points of the node 2 start. Locatedin the elements array.
    end2: (int) Index where the points of the node 2 end. Locatedin the elements array.
    start3: (int) Index where the points of the node 3 start. Locatedin the elements array.
    end3: (int) Index where the points of the node 3 end. Locatedin the elements array.
    bn: (int) NUmber of bins in the XY histogram.
    ds: (double) Constant to calculate the bin index where the triangle count will be stored.
    ddmax: (float) The square of the maximum distance of interest between points.
    size_box: (float) The size of the box where the points were contained. It is used to calculate the proyected nodes.
    fx_2: (bool) True if the node number 2 is proyected in the x direction.
    fy_2: (bool) True if the node number 2 is proyected in the y direction.
    fz_2: (bool) True if the node number 2 is proyected in the z direction.
    fx_3: (bool) True if the node number 3 is proyected in the x direction.
    fy_3: (bool) True if the node number 3 is proyected in the y direction.
    fz_3: (bool) True if the node number 3 is proyected in the z direction.
    bn_offset: (int) Number of randomfile if there are many random files
    */

    int bnx, bny, bnz, bin;
    float x1,y1,z1,w1,x2,y2,z2,w2,x3,y3,z3;
    float dx12, dy12, dz12, dx23, dy23, dz23, dx31, dy31, dz31;
    double d12,d23,d31;
    double v;

    for (int i=start1; i<end1; i++){
        //Node 1 is never proyected
        x1 = elementsX[i].x;
        y1 = elementsX[i].y;
        z1 = elementsX[i].z;
        w1 = elementsX[i].w;
        for (int j=start2; j<end2; j++){
            x2 = elementsX[j].x;
            y2 = elementsX[j].y;
            z2 = elementsX[j].z;
            w2 = elementsX[j].w;
            dx12 = fabsf(x2-x1) - size_box*fx_2;
            dy12 = fabsf(y2-y1) - size_box*fy_2;
            dz12 = fabsf(z2-z1) - size_box*fz_2;
            d12 = dx12*dx12 + dy12*dy12 + dz12*dz12;
            if (d12 < dd_max && d12>0){
                v = w1*w2;
                d12 = sqrt(d12);
                for (int k=start3; k<end3; k++){
                    x3 = elementsY[k].x;
                    y3 = elementsY[k].y;
                    z3 = elementsY[k].z;
                    dx23 = fabsf(x3-x2) - fabsf(size_box*fx_2 - size_box*fx_3);
                    dy23 = fabsf(y3-y2) - fabsf(size_box*fy_2 - size_box*fy_3);
                    dz23 = fabsf(z3-z2) - fabsf(size_box*fz_2 - size_box*fz_3);
                    d23 = dx23*dx23 + dy23*dy23 + dz23*dz23;
                    if (d23 < dd_max && d23>0){
                        dx31 = fabsf(x3-x1) - size_box*fx_3;
                        dy31 = fabsf(y3-y1) - size_box*fy_3;
                        dz31 = fabsf(z3-z1) - size_box*fz_3;
                        d31 = dx31*dx31 + dy31*dy31 + dz31*dz31;
                        if (d31 < dd_max && d31>0){
                            d23 = sqrt(d23);
                            d31 = sqrt(d31);

                            bnx = (int)(d12*ds)*bn*bn;
                            if (bnx>(bn*bn*(bn-1))) continue;
                            bny = (int)(d23*ds)*bn;
                            if (bny>(bn*(bn-1))) continue;
                            bnz = (int)(d31*ds);
                            if (bnz>(bn-1)) continue;
                            bin = bnx + bny + bnz;
                            bin += bn_offset*bn*bn*bn;
                            v *= elementsY[k].w;
                            
                            atomicAdd(&XXY[bin],v);
                        }
                    }
                }
            }
        }
    }
}

//DDD pure histogram
__global__ void XXX3iso_BPC(double *XXX, PointW3D *elements, DNode *nodeD, int nonzero_nodes, int bn, float dmax, float d_max_node, float size_box, float size_node, int node_offset=0, int bn_offset=0){
    /*
    Kernel function to calculate the pure histograms for the 3 point isotropic correlation function. 
    This version does considers boudary periodic conditions. It stores the counts in the XXX histogram.

    args:
    XXX: (double*) The histogram where the distances are counted.
    elementsX: (PointW3D*) Array of the points ordered coherently with the nodes. For the X points.
    nodeX: (DNode) Array of DNodes each of which define a node and the elements of element that correspond to that node. For the X points
    nonzero_Xnodes: (int) Number of nonzero nodes where the points have been classificated. For the X points
    bn: (int) NUmber of bins in the XY histogram.
    dmax: (float) The maximum distance of interest between points.
    d_max_node: (float) The maximum internodal distance.
    size_box: (float) The size of the box where the points were contained. It is used for the boundary periodic conditions
    size_node: (float) Size of the nodes.
    */

    //Distributes all the indexes equitatively into the n_kernelc_calls.
    int idx1 = node_offset + blockIdx.x * blockDim.x + threadIdx.x;
    int idx2 = node_offset + blockIdx.y * blockDim.y + threadIdx.y;
    int idx3 = node_offset + blockIdx.z * blockDim.z + threadIdx.z;
    
    if (idx1<(nonzero_nodes+node_offset) && idx2<(nonzero_nodes+node_offset) && idx3<(nonzero_nodes+node_offset)){
        int end1 = nodeD[idx1].end, end2 = nodeD[idx2].end, end3 = nodeD[idx3].end;
        int start1 = nodeD[idx1].start, start2 = nodeD[idx2].start, start3 = nodeD[idx3].start;
        float dd_max=dmax*dmax;
        double ds = floor(((double)(bn)/dmax)*1000000)/1000000;

        float nx1=nodeD[idx1].nodepos.x, ny1=nodeD[idx1].nodepos.y, nz1=nodeD[idx1].nodepos.z;
        float nx2=nodeD[idx2].nodepos.x, ny2=nodeD[idx2].nodepos.y, nz2=nodeD[idx2].nodepos.z;
        float nx3=nodeD[idx3].nodepos.x, ny3=nodeD[idx3].nodepos.y, nz3=nodeD[idx3].nodepos.z;
        float dxn12 = fabsf(nx2-nx1), dyn12 = fabsf(ny2-ny1), dzn12 = fabsf(nz2-nz1);
        float dxn23 = fabsf(nx3-nx2), dyn23 = fabsf(ny3-ny2), dzn23 = fabsf(nz3-nz2);
        float dxn31 = fabsf(nx1-nx3), dyn31 = fabsf(ny1-ny3), dzn31 = fabsf(nz1-nz3);
        float dd_nod12 = dxn12*dxn12+dyn12*dyn12+dzn12*dzn12;
        float dd_nod23 = dxn23*dxn23+dyn23*dyn23+dzn23*dzn23;
        float dd_nod31 = dxn31*dxn31+dyn31*dyn31+dzn31*dzn31;

        //Front vars
        float f_dmax = dmax+size_node;
        float size_box2=size_box*size_box, _f_dmax = size_box - f_dmax;
        bool fx_2 = ((nx1<=f_dmax)&&(nx2>=_f_dmax))||((nx2<=f_dmax)&&(nx1>=_f_dmax));
        bool fy_2 = ((ny1<=f_dmax)&&(ny2>=_f_dmax))||((ny2<=f_dmax)&&(ny1>=_f_dmax));
        bool fz_2 = ((nz1<=f_dmax)&&(nz2>=_f_dmax))||((nz2<=f_dmax)&&(nz1>=_f_dmax));
        bool fx_3 = ((nx1<=f_dmax)&&(nx3>=_f_dmax))||((nx3<=f_dmax)&&(nx1>=_f_dmax));;
        bool fy_3 = ((ny1<=f_dmax)&&(ny3>=_f_dmax))||((ny3<=f_dmax)&&(ny1>=_f_dmax));;
        bool fz_3 = ((nz1<=f_dmax)&&(nz3>=_f_dmax))||((nz3<=f_dmax)&&(nz1>=_f_dmax));;
        float f_dd_nod12, f_dd_nod23, f_dd_nod31;

        //No proyection
        if (dd_nod12 <= d_max_node && dd_nod23 <= d_max_node && dd_nod31 <= d_max_node){
            //Regular counting. No BPC
            count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, false, false, false, bn_offset);
        }

        //============ Only node 3 proyections ================
        if (dd_nod12 <= d_max_node && (fx_3 || fy_3 || fz_3)){
            //x proyection
            if (fx_3){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dxn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, true, false, false, bn_offset);
                    }
                }
            }
            //y proyection
            if (fy_3){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dyn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, false, true, false, bn_offset);
                    }
                }
            }
            //z proyection
            if (fz_3){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dzn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, false, false, true, bn_offset);
                    }
                }
            }
            //xy proyection
            if (fx_3 && fy_3){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, true, true, false, bn_offset);
                    }
                }
            }
            //xz proyection
            if (fx_3 && fz_3){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, true, false, true, bn_offset);
                    }
                }
            }
            //yz proyection
            if (fy_3 && fz_3){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, false, true, true, bn_offset);
                    }
                }
            }
            //xyz proyection
            if (fx_3 && fy_3 && fz_3){
                f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, true, true, true, bn_offset);
                    }
                }
            }
        }
        
        //============ Only node 2 proyections ================
        
        if (dd_nod31 <= d_max_node && (fx_2 || fy_2 || fz_2)){
            //x proyection
            if (fx_2){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dxn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + size_box2 - 2*dxn12*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, false, false, false, bn_offset);
                    }
                }
            }
            //y proyection
            if (fy_2){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dyn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + size_box2 - 2*dyn12*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, false, false, false, bn_offset);
                    }
                }
            }
            //z proyection
            if (fz_2){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dzn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + size_box2 - 2*dzn12*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, false, false, false, bn_offset);
                    }
                }
            }
            //xy proyection
            if (fx_2 && fy_2){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dyn12)*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, false, false, false, bn_offset);
                    }
                }
            }
            //xz proyection
            if (fx_2 && fz_2){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dzn12)*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, false, false, false, bn_offset);
                    }
                }
            }
            //yz proyection
            if (fy_2 && fz_2){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dyn12 + dzn12)*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, false, false, false, bn_offset);
                    }
                }
            }
            //xyz proyection
            if (fx_2 && fy_2 && fz_2){
                f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + 3*size_box2 - 2*(dxn12 + dyn12 + dzn12)*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, false, false, false, bn_offset);
                    }
                }
            }
        }
        
        //============ Both nodes are proyected ===============
        if ((fx_2 || fy_2 || fz_2) && (fx_3 || fy_3 || fz_3)){
            
            //======== Both nodes are proyected the same ========
            if (dd_nod23 <= d_max_node){
                //x proyection
                if (fx_2 && fx_3){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + size_box2 - 2*dxn12*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, false, false, bn_offset);
                        }
                    }
                }
                //y proyection
                if (fy_2 && fy_3){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + size_box2 - 2*dyn12*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, false, true, false, bn_offset);
                        }
                    }
                }
                //z proyection
                if (fz_2 && fz_3){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + size_box2 - 2*dzn12*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, false, false, true, bn_offset);
                        }
                    }
                }
                //xy proyection
                if (fx_2 && fx_3 && fy_2 && fy_3){
                    f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                    if (f_dd_nod23 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dyn12)*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, true, true, false, bn_offset);
                        }
                    }
                }
                //xz proyection
                if (fx_2 && fx_3 && fz_2 && fz_3){
                    f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                    if (f_dd_nod23 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dzn12)*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, true, false, true, bn_offset);
                        }
                    }
                }
                //yz proyection
                if (fy_2 && fy_3 && fz_2 && fz_3){
                    f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                    if (f_dd_nod23 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dyn12 + dzn12)*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, false, true, true, bn_offset);
                        }
                    }
                }
                //xyz proyection
                if (fx_2 && fx_3 && fy_2 && fy_3 && fz_2 && fz_3){
                    f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                    if (f_dd_nod23 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + 3*size_box2 - 2*(dxn12 + dyn12 + dzn12)*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, true, true, true, bn_offset);
                        }
                    }
                }
            }

            //====== Both nodes are proyected differently =======
            //node 2 x proyection
            if (fx_2){
                f_dd_nod12 = dd_nod12 + size_box2 - 2*dxn12*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 y proyection
            if (fy_2){
                f_dd_nod12 = dd_nod12 + size_box2 - 2*dyn12*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 z proyection
            if (fz_2){
                f_dd_nod12 = dd_nod12 + size_box2 - 2*dzn12*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //xy proyection
            if (fx_2 && fy_2){
                f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dyn12)*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dzn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 xz proyection
            if (fx_2 && fz_2){
                f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dzn12)*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 yz proyection
            if (fy_2 && fz_2){
                f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dzn12 + dyn12)*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 xyz proyection
            if (fx_2 && fy_2 && fz_2){
                f_dd_nod12 = dd_nod12 + 3*size_box2 - 2*(dxn12 + dyn12 + dzn12)*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123(XXX, elements, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, false, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
        }

    }
}

__global__ void XXY3iso_BPC(double *XXY, PointW3D *elementsX, DNode *nodeX, int nonzero_Xnodes, PointW3D *elementsY, DNode *nodeY, int nonzero_Ynodes, int bn, float dmax, float d_max_node, float size_box, float size_node, int node_offset, int bn_offset, bool isDDR){
    /*
    Kernel function to calculate the mixed histograms for the 3 point isotropic correlation function. 
    This version does considers boudary periodic conditions. It stores the counts in the XXY histogram.

    args:
    XXY: (double*) The histogram where the distances are counted.
    elementsX: (PointW3D*) Array of the points ordered coherently with the nodes. For the X points.
    nodeX: (DNode) Array of DNodes each of which define a node and the elements of element that correspond to that node. For the X points
    nonzero_Xnodes: (int) Number of nonzero nodes where the points have been classificated. For the X points
    elementsY: (PointW3D*) Array of the points ordered coherently with the nodes. For the Y points.
    nodeY: (DNode) Array of DNodes each of which define a node and the elements of element that correspond to that node. For the Y points
    nonzero_Ynodes: (int) Number of nonzero nodes where the points have been classificated. For the Y points
    bn: (int) NUmber of bins in the XY histogram.
    dmax: (float) The maximum distance of interest between points.
    d_max_node: (float) The maximum internodal distance.
    size_box: (float) The size of the box where the points were contained. It is used for the boundary periodic conditions
    size_node: (float) Size of the nodes.
    isDDR: (bool) To know if the XX or Y node may have many entries from many random nodes
    */

    //Distributes all the indexes equitatively into the n_kernelc_calls.
    int idx1 = (!isDDR)*node_offset + blockIdx.x * blockDim.x + threadIdx.x;
    int idx2 = (!isDDR)*node_offset + blockIdx.y * blockDim.y + threadIdx.y;
    int idx3 = isDDR*node_offset + blockIdx.z * blockDim.z + threadIdx.z;
    
    if (idx1<(nonzero_Xnodes + (!isDDR)*node_offset) && idx2<(nonzero_Xnodes + (!isDDR)*node_offset) && idx3<(nonzero_Ynodes + isDDR*node_offset)){
        int end1 = nodeX[idx1].end, end2 = nodeX[idx2].end, end3 = nodeY[idx3].end;
        int start1 = nodeX[idx1].start, start2 = nodeX[idx2].start, start3 = nodeY[idx3].start;
        float dd_max=dmax*dmax;
        double ds = floor(((double)(bn)/dmax)*1000000)/1000000;

        float nx1=nodeX[idx1].nodepos.x, ny1=nodeX[idx1].nodepos.y, nz1=nodeX[idx1].nodepos.z;
        float nx2=nodeX[idx2].nodepos.x, ny2=nodeX[idx2].nodepos.y, nz2=nodeX[idx2].nodepos.z;
        float nx3=nodeY[idx3].nodepos.x, ny3=nodeY[idx3].nodepos.y, nz3=nodeY[idx3].nodepos.z;
        float dxn12 = fabsf(nx2-nx1), dyn12 = fabsf(ny2-ny1), dzn12 = fabsf(nz2-nz1);
        float dxn23 = fabsf(nx3-nx2), dyn23 = fabsf(ny3-ny2), dzn23 = fabsf(nz3-nz2);
        float dxn31 = fabsf(nx1-nx3), dyn31 = fabsf(ny1-ny3), dzn31 = fabsf(nz1-nz3);
        float dd_nod12 = dxn12*dxn12+dyn12*dyn12+dzn12*dzn12;
        float dd_nod23 = dxn23*dxn23+dyn23*dyn23+dzn23*dzn23;
        float dd_nod31 = dxn31*dxn31+dyn31*dyn31+dzn31*dzn31;

        //Front vars
        float f_dmax = dmax+size_node;
        float size_box2=size_box*size_box, _f_dmax = size_box - f_dmax;
        bool fx_2 = ((nx1<=f_dmax)&&(nx2>=_f_dmax))||((nx2<=f_dmax)&&(nx1>=_f_dmax));
        bool fy_2 = ((ny1<=f_dmax)&&(ny2>=_f_dmax))||((ny2<=f_dmax)&&(ny1>=_f_dmax));
        bool fz_2 = ((nz1<=f_dmax)&&(nz2>=_f_dmax))||((nz2<=f_dmax)&&(nz1>=_f_dmax));
        bool fx_3 = ((nx1<=f_dmax)&&(nx3>=_f_dmax))||((nx3<=f_dmax)&&(nx1>=_f_dmax));;
        bool fy_3 = ((ny1<=f_dmax)&&(ny3>=_f_dmax))||((ny3<=f_dmax)&&(ny1>=_f_dmax));;
        bool fz_3 = ((nz1<=f_dmax)&&(nz3>=_f_dmax))||((nz3<=f_dmax)&&(nz1>=_f_dmax));;
        float f_dd_nod12, f_dd_nod23, f_dd_nod31;

        //No proyection
        if (dd_nod12 <= d_max_node && dd_nod23 <= d_max_node && dd_nod31 <= d_max_node){
            //Regular counting. No BPC
            count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, false, false, false, bn_offset);
        }

        //============ Only node 3 proyections ================
        if (dd_nod12 <= d_max_node && (fx_3 || fy_3 || fz_3)){
            //x proyection
            if (fx_3){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dxn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, true, false, false, bn_offset);
                    }
                }
            }
            //y proyection
            if (fy_3){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dyn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, false, true, false, bn_offset);
                    }
                }
            }
            //z proyection
            if (fz_3){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dzn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, false, false, true, bn_offset);
                    }
                }
            }
            //xy proyection
            if (fx_3 && fy_3){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, true, true, false, bn_offset);
                    }
                }
            }
            //xz proyection
            if (fx_3 && fz_3){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, true, false, true, bn_offset);
                    }
                }
            }
            //yz proyection
            if (fy_3 && fz_3){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, false, true, true, bn_offset);
                    }
                }
            }
            //xyz proyection
            if (fx_3 && fy_3 && fz_3){
                f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, false, true, true, true, bn_offset);
                    }
                }
            }
        }
        
        //============ Only node 2 proyections ================
        
        if (dd_nod31 <= d_max_node && (fx_2 || fy_2 || fz_2)){
            //x proyection
            if (fx_2){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dxn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + size_box2 - 2*dxn12*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, false, false, false, bn_offset);
                    }
                }
            }
            //y proyection
            if (fy_2){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dyn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + size_box2 - 2*dyn12*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, false, false, false, bn_offset);
                    }
                }
            }
            //z proyection
            if (fz_2){
                f_dd_nod23 = dd_nod23 + size_box2 - 2*dzn23*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + size_box2 - 2*dzn12*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, false, false, false, bn_offset);
                    }
                }
            }
            //xy proyection
            if (fx_2 && fy_2){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dyn12)*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, false, false, false, bn_offset);
                    }
                }
            }
            //xz proyection
            if (fx_2 && fz_2){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dzn12)*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, false, false, false, bn_offset);
                    }
                }
            }
            //yz proyection
            if (fy_2 && fz_2){
                f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dyn12 + dzn12)*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, false, false, false, bn_offset);
                    }
                }
            }
            //xyz proyection
            if (fx_2 && fy_2 && fz_2){
                f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                if (f_dd_nod23 <= d_max_node){
                    f_dd_nod12 = dd_nod12 + 3*size_box2 - 2*(dxn12 + dyn12 + dzn12)*size_box;
                    if (f_dd_nod12 <= d_max_node){
                        count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, false, false, false, bn_offset);
                    }
                }
            }
        }
        
        //============ Both nodes are proyected ===============
        if ((fx_2 || fy_2 || fz_2) && (fx_3 || fy_3 || fz_3)){
            
            //======== Both nodes are proyected the same ========
            if (dd_nod23 <= d_max_node){
                //x proyection
                if (fx_2 && fx_3){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + size_box2 - 2*dxn12*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, false, false, bn_offset);
                        }
                    }
                }
                //y proyection
                if (fy_2 && fy_3){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + size_box2 - 2*dyn12*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, false, true, false, bn_offset);
                        }
                    }
                }
                //z proyection
                if (fz_2 && fz_3){
                    f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                    if (f_dd_nod31 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + size_box2 - 2*dzn12*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, false, false, true, bn_offset);
                        }
                    }
                }
                //xy proyection
                if (fx_2 && fx_3 && fy_2 && fy_3){
                    f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                    if (f_dd_nod23 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dyn12)*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, true, true, false, bn_offset);
                        }
                    }
                }
                //xz proyection
                if (fx_2 && fx_3 && fz_2 && fz_3){
                    f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                    if (f_dd_nod23 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dzn12)*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, true, false, true, bn_offset);
                        }
                    }
                }
                //yz proyection
                if (fy_2 && fy_3 && fz_2 && fz_3){
                    f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                    if (f_dd_nod23 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dyn12 + dzn12)*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, false, true, true, bn_offset);
                        }
                    }
                }
                //xyz proyection
                if (fx_2 && fx_3 && fy_2 && fy_3 && fz_2 && fz_3){
                    f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                    if (f_dd_nod23 <= d_max_node){
                        f_dd_nod12 = dd_nod12 + 3*size_box2 - 2*(dxn12 + dyn12 + dzn12)*size_box;
                        if (f_dd_nod12 <= d_max_node){
                            count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, true, true, true, bn_offset);
                        }
                    }
                }
            }

            //====== Both nodes are proyected differently =======
            //node 2 x proyection
            if (fx_2){
                f_dd_nod12 = dd_nod12 + size_box2 - 2*dxn12*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 y proyection
            if (fy_2){
                f_dd_nod12 = dd_nod12 + size_box2 - 2*dyn12*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, false, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, false, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 z proyection
            if (fz_2){
                f_dd_nod12 = dd_nod12 + size_box2 - 2*dzn12*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, false, true, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //xy proyection
            if (fx_2 && fy_2){
                f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dyn12)*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dzn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, false, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 xz proyection
            if (fx_2 && fz_2){
                f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dxn12 + dzn12)*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, false, true, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, false, true, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 yz proyection
            if (fy_2 && fz_2){
                f_dd_nod12 = dd_nod12 + 2*size_box2 - 2*(dzn12 + dyn12)*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dxn23 + dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xyz proyection
                    if (fx_3 && fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 3*size_box2 - 2*(dxn31 + dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, false, true, true, true, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
            //node 2 xyz proyection
            if (fx_2 && fy_2 && fz_2){
                f_dd_nod12 = dd_nod12 + 3*size_box2 - 2*(dxn12 + dyn12 + dzn12)*size_box;
                if (f_dd_nod12 <= d_max_node){
                    //node 3 x proyection
                    if (fx_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dxn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dyn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, true, false, false, bn_offset);
                            }
                        }
                    }
                    //node 3 y proyection
                    if (fy_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dyn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, false, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 z proyection
                    if (fz_3){
                        f_dd_nod31 = dd_nod31 + size_box2 - 2*dzn31*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 2*size_box2 - 2*(dxn23 + dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, false, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 xy proyection
                    if (fx_3 && fy_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dyn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dzn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, true, true, false, bn_offset);
                            }
                        }
                    }
                    //node 3 xz proyection
                    if (fx_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dxn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + 3*size_box2 - 2*(dyn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, true, false, true, bn_offset);
                            }
                        }
                    }
                    //node 3 yz proyection
                    if (fy_3 && fz_3){
                        f_dd_nod31 = dd_nod31 + 2*size_box2 - 2*(dyn31 + dzn31)*size_box;
                        if (f_dd_nod31 <= d_max_node){
                            f_dd_nod23 = dd_nod23 + size_box2 - 2*(dxn23)*size_box;
                            if (f_dd_nod23 <= d_max_node){
                                count123_mixed(XXY, elementsX, elementsY, start1, end1, start2, end2, start3, end3, bn, ds, dd_max, size_box, true, true, true, false, true, true, bn_offset);
                            }
                        }
                    }
                }
            }
        }

    }
}

//Analytic formulas for RRR and mixed histograms
__global__ void DD2iso_forBPC(double *XX_ff_av_ref, double *XX_ff_av, PointW3D *elements, DNode *nodeD, int nonzero_nodes, int bn_ff_av_ref, int bn_ff_av, float dmax, float d_max_node, float size_box, float size_node){
    /*
    Kernel function to calculate the pure histograms WITH boundary periodic conditions. It stores the counts in the XX_ff_av_ref and XX_ff_av histogram.
    This function does the same calculations to save the same distances countings in different histograms.

    args:
    float size_box, float size_node
    XX_ff_av_ref: (double*) The histogram where the distances are counted.
    XX_ff_av: (double*) The histogram where the distances are counted.
    elements: (PointW3D*) Array of the points ordered coherently with the nodes.
    nodeD: (DNode) Array of DNodes each of which define a node and the elements of element that correspond to that node.
    nonzero_nodes: (int) Number of nonzero nodes where the points have been classificated. For the data points
    partitions: (int) Number of partitions that are fitted by box side.
    bn_ff_av_ref: (int) NUmber of bins in the XX_ff_av_ref histogram.
    bn_ff_av: (int) NUmber of bins in the XX_ff_av histogram.
    dmax: (dmax) The maximum distance of interest between points.
    d_max_node: (float) The maximum internodal distance.
    size_box: (float) The size of the box where the points were contained. It is used for the boundary periodic conditions
    size_node: (float) Size of the nodes.
    */

    //Distributes all the indexes equitatively into the n_kernelc_calls.
    int idx1 = blockIdx.x * blockDim.x + threadIdx.x;
    int idx2 = blockIdx.y * blockDim.y + threadIdx.y;
    double v;

    if (idx1<nonzero_nodes && idx2<nonzero_nodes){

        float nx1=nodeD[idx1].nodepos.x, ny1=nodeD[idx1].nodepos.y, nz1=nodeD[idx1].nodepos.z;
        float nx2=nodeD[idx2].nodepos.x, ny2=nodeD[idx2].nodepos.y, nz2=nodeD[idx2].nodepos.z;
        float ds_ff_av_ref = ((float)(bn_ff_av_ref))/dmax, ds_ff_av = ((float)(bn_ff_av))/dmax, dd_max=dmax*dmax;
        float dxn12=fabsf(nx2-nx1), dyn12=fabsf(ny2-ny1), dzn12=fabsf(nz2-nz1);
        float dd_nod12 = dxn12*dxn12 + dyn12*dyn12 + dzn12*dzn12;
        
        float x1,y1,z1,x2,y2,z2,d;
        float dx,dy,dz;
        int bin, end1=nodeD[idx1].end, end2=nodeD[idx2].end;
        
        //Front vars
        float f_dmax = dmax+size_node;
        float _f_dmax = size_box - f_dmax;
        bool boundx = ((nx1<=f_dmax)&&(nx2>=_f_dmax))||((nx2<=f_dmax)&&(nx1>=_f_dmax));
        bool boundy = ((ny1<=f_dmax)&&(ny2>=_f_dmax))||((ny2<=f_dmax)&&(ny1>=_f_dmax));
        bool boundz = ((nz1<=f_dmax)&&(nz2>=_f_dmax))||((nz2<=f_dmax)&&(nz1>=_f_dmax));
        float f_dxn12, f_dyn12, f_dzn12;

        //Regular histogram calculation
        if (dd_nod12 <= d_max_node){

            for (int i=nodeD[idx1].start; i<end1; ++i){
                x1 = elements[i].x;
                y1 = elements[i].y;
                z1 = elements[i].z;
                for (int j=nodeD[idx2].start; j<end2; ++j){
                    x2 = elements[j].x;
                    y2 = elements[j].y;
                    z2 = elements[j].z;
                    d = (x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)+(z2-z1)*(z2-z1);
                    if (d<dd_max && d>0){
                        d = sqrt(d);
                        v = elements[i].w*elements[j].w;
                        bin = (int)(d*ds_ff_av_ref);
                        atomicAdd(&XX_ff_av_ref[bin],v);
                        bin = (int)(d*ds_ff_av);
                        atomicAdd(&XX_ff_av[bin],v);
                    }
                }
            }
        }
        
        //Z front proyection
        if (boundz){
            f_dzn12 = size_box-dzn12;
            dd_nod12 = dxn12*dxn12+dyn12*dyn12+f_dzn12*f_dzn12;
            if (dd_nod12 <= d_max_node){

                for (int i=nodeD[idx1].start; i<end1; ++i){
                    x1 = elements[i].x;
                    y1 = elements[i].y;
                    z1 = elements[i].z;
                    for (int j=nodeD[idx2].start; j<end2; ++j){
                        x2 = elements[j].x;
                        y2 = elements[j].y;
                        z2 = elements[j].z;
                        dz = size_box-fabsf(z2-z1);
                        d = (x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)+dz*dz;
                        if (d<dd_max && d>0){
                            d = sqrt(d);
                            v = elements[i].w*elements[j].w;
                            bin = (int)(d*ds_ff_av_ref);
                            atomicAdd(&XX_ff_av_ref[bin],v);
                            bin = (int)(d*ds_ff_av);
                            atomicAdd(&XX_ff_av[bin],v);
                        }
                    }
                }
            }
        }

        //Y front proyection
        if (boundy){
            f_dyn12 = size_box-dyn12;
            dd_nod12 = dxn12*dxn12+f_dyn12*f_dyn12+dzn12*dzn12;
            if (dd_nod12 <= d_max_node){

                for (int i=nodeD[idx1].start; i<end1; ++i){
                    x1 = elements[i].x;
                    y1 = elements[i].y;
                    z1 = elements[i].z;
                    for (int j=nodeD[idx2].start; j<end2; ++j){
                        x2 = elements[j].x;
                        y2 = elements[j].y;
                        z2 = elements[j].z;
                        dy = size_box-fabsf(y2-y1);
                        d = (x2-x1)*(x2-x1)+dy*dy+(z2-z1)*(z2-z1);
                        if (d<dd_max && d>0){
                            d = sqrt(d);
                            v = elements[i].w*elements[j].w;
                            bin = (int)(d*ds_ff_av_ref);
                            atomicAdd(&XX_ff_av_ref[bin],v);
                            bin = (int)(d*ds_ff_av);
                            atomicAdd(&XX_ff_av[bin],v);
                        }
                    }
                }
            }
        }
        
        //X front proyection
        if (boundx){
            f_dxn12 = size_box-dxn12;
            dd_nod12 = f_dxn12*f_dxn12+dyn12*dyn12+dzn12*dzn12;
            if (dd_nod12 <= d_max_node){

                for (int i=nodeD[idx1].start; i<end1; ++i){
                    x1 = elements[i].x;
                    y1 = elements[i].y;
                    z1 = elements[i].z;
                    for (int j=nodeD[idx2].start; j<end2; ++j){
                        x2 = elements[j].x;
                        y2 = elements[j].y;
                        z2 = elements[j].z;
                        dx = size_box-fabsf(x2-x1);
                        d = dx*dx+(y2-y1)*(y2-y1)+(z2-z1)*(z2-z1);
                        if (d<dd_max && d>0){
                            d = sqrt(d);
                            v = elements[i].w*elements[j].w;
                            bin = (int)(d*ds_ff_av_ref);
                            atomicAdd(&XX_ff_av_ref[bin],v);
                            bin = (int)(d*ds_ff_av);
                            atomicAdd(&XX_ff_av[bin],v);
                        }
                    }
                }
            }
        }
        
        //XY front proyection
        if (boundx && boundy){
            f_dxn12 = size_box-dxn12;
            f_dyn12 = size_box-dyn12;
            dd_nod12 = f_dxn12*f_dxn12+f_dyn12*f_dyn12+dzn12*dzn12;
            if (dd_nod12 <= d_max_node){

                for (int i=nodeD[idx1].start; i<end1; ++i){
                    x1 = elements[i].x;
                    y1 = elements[i].y;
                    z1 = elements[i].z;
                    for (int j=nodeD[idx2].start; j<end2; ++j){
                        x2 = elements[j].x;
                        y2 = elements[j].y;
                        z2 = elements[j].z;
                        dx = size_box-fabsf(x2-x1);
                        dy = size_box-fabsf(y2-y1);
                        d = dx*dx+dy*dy+(z2-z1)*(z2-z1);
                        if (d<dd_max && d>0){
                            d = sqrt(d);
                            v = elements[i].w*elements[j].w;
                            bin = (int)(d*ds_ff_av_ref);
                            atomicAdd(&XX_ff_av_ref[bin],v);
                            bin = (int)(d*ds_ff_av);
                            atomicAdd(&XX_ff_av[bin],v);
                        }
                    }
                }
            }
        }

                
        //XZ front proyection
        if (boundx && boundz){
            f_dxn12 = size_box-dxn12;
            f_dzn12 = size_box-dzn12;
            dd_nod12 = f_dxn12*f_dxn12+dyn12*dyn12+f_dzn12*f_dzn12;
            if (dd_nod12 <= d_max_node){

                for (int i=nodeD[idx1].start; i<end1; ++i){
                    x1 = elements[i].x;
                    y1 = elements[i].y;
                    z1 = elements[i].z;
                    for (int j=nodeD[idx2].start; j<end2; ++j){
                        x2 = elements[j].x;
                        y2 = elements[j].y;
                        z2 = elements[j].z;
                        dx = size_box-fabsf(x2-x1);
                        dz = size_box-fabsf(z2-z1);
                        d = dx*dx+(y2-y1)*(y2-y1)+dz*dz;
                        if (d<dd_max && d>0){
                            d = sqrt(d);
                            v = elements[i].w*elements[j].w;
                            bin = (int)(d*ds_ff_av_ref);
                            atomicAdd(&XX_ff_av_ref[bin],v);
                            bin = (int)(d*ds_ff_av);
                            atomicAdd(&XX_ff_av[bin],v);
                        }
                    }
                }
            }
        }
        
        //YZ front proyection
        if (boundy && boundz){
            f_dyn12 = size_box-dyn12;
            f_dzn12 = size_box-dzn12;
            dd_nod12 = dxn12*dxn12+f_dyn12*f_dyn12+f_dzn12*f_dzn12;
            if (dd_nod12 <= d_max_node){

                for (int i=nodeD[idx1].start; i<end1; ++i){
                    x1 = elements[i].x;
                    y1 = elements[i].y;
                    z1 = elements[i].z;
                    for (int j=nodeD[idx2].start; j<end2; ++j){
                        x2 = elements[j].x;
                        y2 = elements[j].y;
                        z2 = elements[j].z;
                        dy = size_box-fabsf(y2-y1);
                        dz = size_box-fabsf(z2-z1);
                        d = (x2-x1)*(x2-x1)+dy*dy+dz*dz;
                        if (d<dd_max && d>0){
                            d = sqrt(d);
                            v = elements[i].w*elements[j].w;
                            bin = (int)(d*ds_ff_av_ref);
                            atomicAdd(&XX_ff_av_ref[bin],v);
                            bin = (int)(d*ds_ff_av);
                            atomicAdd(&XX_ff_av[bin],v);
                        }
                    }
                }
            }
        }
        
        //XYZ front proyection
        if (boundx && boundy && boundz){
            f_dxn12 = size_box-dxn12;
            f_dyn12 = size_box-dyn12;
            f_dzn12 = size_box-dzn12;
            dd_nod12 = f_dxn12*f_dxn12+f_dyn12*f_dyn12+f_dzn12*f_dzn12;
            if (dd_nod12 <= d_max_node){

                for (int i=nodeD[idx1].start; i<end1; ++i){
                    x1 = elements[i].x;
                    y1 = elements[i].y;
                    z1 = elements[i].z;
                    for (int j=nodeD[idx2].start; j<end2; ++j){
                        x2 = elements[j].x;
                        y2 = elements[j].y;
                        z2 = elements[j].z;
                        dx = size_box-fabsf(x2-x1);
                        dy = size_box-fabsf(y2-y1);
                        dz = size_box-fabsf(z2-z1);
                        d = dx*dx+dy*dy+dz*dz;
                        if (d<dd_max && d>0){
                            d = sqrt(d);
                            v = elements[i].w*elements[j].w;
                            bin = (int)(d*ds_ff_av_ref);
                            atomicAdd(&XX_ff_av_ref[bin],v);
                            bin = (int)(d*ds_ff_av);
                            atomicAdd(&XX_ff_av[bin],v);
                        }
                    }
                }
            }
        }

    }

}

// Get make_histoRR from 2pcfisotropic bpc analytic

__global__ void make_ff_av(double *ff_av, double *XX, double *YY, float dmax, int bn, int bn_ff_av, int ptt){
    
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (i<bn && j<ptt){
        int i_ = i*ptt;
        double ri = i*dmax/(double)bn;
        double rj = (j+0.5)*dmax/(double)bn_ff_av;
        double v = (ri + rj)*((*(XX+i_+j)/(*(YY+i_+j))) - 1)/(double)(ptt);
        
        atomicAdd(&ff_av[i],v);

    }

}

__global__ void make_ff_av_ref(double *ff_av_ref, double *DD, double *RR, float dmax, int bn, int bn_ref, int ptt){

    int i = blockIdx.z * blockDim.z + threadIdx.z;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    int k = blockIdx.x * blockDim.x + threadIdx.x;

    if (i<bn && j<bn_ref && k<ptt){
        double dr = dmax/(double)bn;
        double dr_ref = dr/bn_ref;
        double dr_ptt_ref = dmax/(double)(ptt*bn_ref*bn);
        double ri = i*dr, rj = j*dr_ref, rk = (k+0.5)*dr_ptt_ref;
        int i_ = i*bn_ref, j_ = j*ptt;

        double f_av  = (ri+rj+rk)*(((*(DD+(i_*ptt)+j_+k))/(*(RR+(i_*ptt)+j_+k))) - 1)/(double)(ptt);

        atomicAdd(&ff_av_ref[i_+j], f_av);
    }

}

__global__ void make_histo_analitic(double *XXY, double *RRR, double *ff_av, double *ff_av_ref, double alpha, double alpha_ref, float dmax, int bn, int bn_ref){
    /*
    This function computes the RRR and DDR analytically from ff_av and ff_av_ref which were calculated from (DD_ff_av and RR_ff_av)
    and (DD_ff_av_ref and RR_ff_av_ref) respectively.
    */

    //Histogram 3D bin indices
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    int k = blockIdx.z * blockDim.z + threadIdx.z;
    
    if (i<bn && j<bn && k<bn){

        double dr = dmax/(double)bn;
        double dr2 = dr*0.5;
        double ri = (double)(i)*dr, rj = (double)(j)*dr, rk = (double)(k)*dr;
        int i_ = i*bn_ref, j_ = j*bn_ref, k_ = k*bn_ref;;
        double r1, r2, r3;
        int short v_in = 0;

        // Check vertices of the 
        // cube to make refinement
        for (int a = 0; a < 2; ++a){
            r1 = ri + ((double)(a)*dr);
            for (int b = 0; b < 2; ++b){
                r2 = rj + ((double)(b)*dr);
                for (int c = 0; c < 2; ++c){
                    r3 = rk + ((double)(c)*dr);
                    //v_in += (r1 + r2 >= r3 && r1 + r3 >= r2 && r2 + r3 >= r1);
                    if (r1 + r2 >= r3 && r1 + r3 >= r2 && r2 + r3 >= r1) ++v_in;
                }
            }
        }

        if (v_in==8){
            double s = alpha*(ri+dr2)*(rj+dr2)*(rk+dr2);
            RRR[i*bn*bn + j*bn + k] = s;
            
            double f = 1;
            f += ff_av[i]/(3*(ri+dr2));
            f += ff_av[j]/(3*(rj+dr2));
            f += ff_av[k]/(3*(rk+dr2));
            f *= s;
            atomicAdd(&XXY[i*bn*bn + j*bn + k],f);

        } else if (v_in<8 && v_in>0){
            bool con = false;
            double dr_ref = dr/bn_ref;
            double dr_ref2 = dr_ref*0.5;
            double S_av = 0.0, f_av = 0.0;
            double c_RRR, f, ru, rv, rw;

            for(int u=0; u<bn_ref; ++u) {
                ru = ri + ((double)(u)*dr_ref);
                for(int v=0; v<bn_ref; ++v) {
                    rv = rj + ((double)(v)*dr_ref);
                    for(int w=0; w<bn_ref; ++w) {
                        rw = rk + ((double)(w)*dr_ref);
                        
                        v_in = 0;
                        for (int a = 0; a < 2; ++a){
                            r1 = ru + ((double)(a)*dr_ref);
                            for (int b = 0; b < 2; ++b){
                                r2 = rv + ((double)(b)*dr_ref);
                                for (int c = 0; c < 2; ++c){
                                    r3 = rw + ((double)(c)*dr_ref);
                                    //v_in += (r1 + r2 >= r3 && r1 + r3 >= r2 && r2 + r3 >= r1);
                                    if (r1 + r2 >= r3 && r1 + r3 >= r2 && r2 + r3 >= r1) ++v_in;
                                }
                            }
                        }

                        if (v_in==8){
                            c_RRR = (ru+dr_ref2)*(rv+dr_ref2)*(rw+dr_ref2);
                            S_av += c_RRR;
                            f = 1;
                            f += (ff_av_ref[i_+u])/(3*(ru+dr_ref2));
                            f += (ff_av_ref[j_+v])/(3*(rv+dr_ref2));
                            f += (ff_av_ref[k_+w])/(3*(rw+dr_ref2));
                            f *= c_RRR;
                            f_av += f;
                            con = true;
                        }
                    }
                }
            }
            
            if (con){
                S_av *= alpha_ref;
                atomicAdd(&RRR[i*bn*bn + j*bn + k],S_av);
                //RRR[i*bn*bn + j*bn + k] = S_av;
                
                f_av *= alpha_ref;
                atomicAdd(&XXY[i*bn*bn + j*bn + k],f_av);
                //XXY[i*bn*bn + j*bn + k] = f_av;
            }
        }
    }
}
