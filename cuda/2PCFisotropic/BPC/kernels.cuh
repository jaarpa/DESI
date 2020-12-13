
#include <math.h>

//====================================================================
//============ Kernels Section ======================================= 
//====================================================================
__device__ void count_frontXX(double *XX, PointW3D *elements, DNode *nodeD, int idx1, int idx2, float dd_nod, float dn_x, float dn_y, float dn_z, bool front_x, bool front_y, bool front_z, float dd_max, float ds, float d_max_node, float size_box){
    
    float dd_nod_f = dd_nod + (front_x + front_y + front_z)*size_box*size_box - 2*size_box*(front_x*dn_x+front_y*dn_y+front_z*dn_z);
    if (dd_nod_f <= d_max_node){
        int bin;
        double v;
        float x1,y1,z1,x2,y2,z2,d;
        int start1 = nodeD[idx1].start, end1 = nodeD[idx1].end;
        int start2 = nodeD[idx2].start, end2 = nodeD[idx2].end;
        for(int i=start1; i<end1; i++){
            x1 = elements[i].x;
            y1 = elements[i].y;
            z1 = elements[i].z;
            for(int j=start2; i<end2; j++){
                x2 = elements[i].x;
                y2 = elements[i].y;
                z2 = elements[i].z;
                d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) + (z2-z1)*(z2-z1);
                if (d<dd_max && d>0){
                    bin = (int)(sqrtf(d)*ds);
                    v = elements[i].w*elements[j].w;
                    atomicAdd(&XX[bin],v);
                }
            }
        }
    }
}

__global__ void make_histoXX(double *XX, PointW3D *elements, DNode *nodeD, int nonzero_nodes, int bn, float dmax, float d_max_node, float size_box, float size_node){
    /*
    Kernel function to calculate the pure histograms. It stores the counts in the XX histogram.

    args:
    XX: (double*) The histogram where the distances are counted.
    elements: (PointW3D*) Array of the points ordered coherently with the nodes.
    node: (DNode) Array of DNodes each of which define a node and the elements of element that correspond to that node.
    partitions: (int) Number of partitions that are fitted by box side.
    bn: (int) NUmber of bins in the XY histogram.
    dmax: (dmax) The maximum distance of interest between points.
    size_node: (float) Size of the nodes
    */

    //Distributes all the indexes equitatively into the n_kernelc_calls.
    int idx1 = blockIdx.x * blockDim.x + threadIdx.x;
    int idx2 = blockIdx.y * blockDim.y + threadIdx.y;
    if (idx1<nonzero_nodes && idx2<nonzero_nodes){
        float nx1=nodeD[idx1].nodepos.x, ny1=nodeD[idx1].nodepos.y, nz1=nodeD[idx1].nodepos.z;
        float nx2=nodeD[idx2].nodepos.x, ny2=nodeD[idx2].nodepos.y, nz2=nodeD[idx2].nodepos.z;
        float ds = ((float)(bn))/dmax, dd_max=dmax*dmax;
        float dxn12=fabsf(nx2-nx1), dyn12=fabsf(ny2-ny1), dzn12=fabsf(nz2-nz1);
        float dd_nod12 = dxn12*dxn12 + dyn12*dyn12 + dzn12*dzn12;
        
        float x1,y1,z1,x2,y2,z2,d;
        float dx,dy,dz;
        int bin, end1=nodeD[idx1].end, end2=nodeD[idx2].end;
        double v;
        
        //Front vars
        float f_dxn12, f_dyn12, f_dzn12, f_dd_nod12;
        /*
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
                    if (d<=dd_max && d>0){
                        bin = (int)(sqrtf(d)*ds);
                        v = elements[i].w*elements[j].w;
                        atomicAdd(&XX[bin],v);
                    }
                }
            }
        }
        */
        
        //Z front proyection
        f_dzn12 = size_box-dzn12;
        f_dd_nod12 = dxn12*dxn12+dyn12*dyn12+f_dzn12*f_dzn12;

        if (f_dd_nod12 <= d_max_node){

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
                    if (d<=dd_max && d>0){
                        bin = (int)(sqrtf(d)*ds);
                        v = elements[i].w*elements[j].w;
                        atomicAdd(&XX[bin],v);
                    }
                }
            }
        }
        
        //Y front proyection
        f_dyn12 = size_box-dyn12;
        f_dd_nod12 = dxn12*dxn12+f_dyn12*f_dyn12+dzn12*dzn12;

        if (f_dd_nod12 <= d_max_node){

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
                    if (d<=dd_max && d>0){
                        bin = (int)(sqrtf(d)*ds);
                        v = elements[i].w*elements[j].w;
                        atomicAdd(&XX[bin],v);
                    }
                }
            }
        }
        
        //X front proyection
        f_dxn12 = size_box-dxn12;
        f_dd_nod12 = f_dxn12*f_dxn12+dyn12*dyn12+dzn12*dzn12;

        if (f_dd_nod12 <= d_max_node){

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
                    if (d<=dd_max && d>0){
                        bin = (int)(sqrtf(d)*ds);
                        v = elements[i].w*elements[j].w;
                        atomicAdd(&XX[bin],v);
                    }
                }
            }
        }
        
        
        //XY front proyection
        f_dxn12 = size_box-dxn12;
        f_dyn12 = size_box-dyn12;
        f_dd_nod12 = f_dxn12*f_dxn12+f_dyn12*f_dyn12+dzn12*dzn12;

        if (f_dd_nod12 <= d_max_node){

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
                    if (d<=dd_max && d>0){
                        bin = (int)(sqrtf(d)*ds);
                        v = elements[i].w*elements[j].w;
                        atomicAdd(&XX[bin],v);
                    }
                }
            }
        }

                
        //XZ front proyection
        f_dxn12 = size_box-dxn12;
        f_dzn12 = size_box-dzn12;
        f_dd_nod12 = f_dxn12*f_dxn12+dyn12*dyn12+f_dzn12*f_dzn12;

        if (f_dd_nod12 <= d_max_node){

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
                    if (d<=dd_max && d>0){
                        bin = (int)(sqrtf(d)*ds);
                        v = elements[i].w*elements[j].w;
                        atomicAdd(&XX[bin],v);
                    }
                }
            }
        }
        
        //YZ front proyection
        f_dyn12 = size_box-dyn12;
        f_dzn12 = size_box-dzn12;
        f_dd_nod12 = dxn12*dxn12+f_dyn12*f_dyn12+f_dzn12*f_dzn12;

        if (f_dd_nod12 <= d_max_node){

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
                    if (d<=dd_max && d>0){
                        bin = (int)(sqrtf(d)*ds);
                        v = elements[i].w*elements[j].w;
                        atomicAdd(&XX[bin],v);
                    }
                }
            }
        }
        
        //YZ front proyection
        f_dxn12 = size_box-dxn12;
        f_dyn12 = size_box-dyn12;
        f_dzn12 = size_box-dzn12;
        f_dd_nod12 = f_dxn12*f_dxn12+f_dyn12*f_dyn12+f_dzn12*f_dzn12;

        if (f_dd_nod12 <= d_max_node){

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
                    if (d<=dd_max && d>0){
                        bin = (int)(sqrtf(d)*ds);
                        v = elements[i].w*elements[j].w;
                        atomicAdd(&XX[bin],v);
                    }
                }
            }
        }

    }
}

__global__ void make_histoXY(double *XY, PointW3D *elementsD, DNode *nodeD, int nonzero_Dnodes, PointW3D *elementsR,  DNode *nodeR, int nonzero_Rnodes, int bn, float dmax, float d_max_node, float size_box){
    /*
    Kernel function to calculate the mixed histogram. It stores the counts in the XY histogram.

    args:
    XY: (double*) The histogram where the distances are counted.
    elementsD: (PointW3D*) Array of the points ordered coherently with the nodes.
    nodeD: (DNode) Array of DNodes each of which define a node and the elements of elementD that correspond to that node.
    elementsR: (PointW3D*) Array of the points ordered coherently with the nodes.
    nodeR: (DNode) Array of RNodes each of which define a node and the elements of elementR that correspond to that node.
    partitions: (int) Number of partitions that are fitted by box side.
    bn: (int) NUmber of bins in the XY histogram.
    dmax: (dmax) The maximum distance of interest between points.
    size_node: (float) Size of the nodes
    */
    int idx1 = blockIdx.x * blockDim.x + threadIdx.x;
    int idx2 = blockIdx.y * blockDim.y + threadIdx.y;
    if (idx1<nonzero_Dnodes && idx2<nonzero_Rnodes){
        
        float nx1=nodeD[idx1].nodepos.x, ny1=nodeD[idx1].nodepos.y, nz1=nodeD[idx1].nodepos.z;
        float nx2=nodeR[idx2].nodepos.x, ny2=nodeR[idx2].nodepos.y, nz2=nodeR[idx2].nodepos.z;
        float dx12=nx2-nx1, dy12=ny2-ny1, dz12=nz2-nz1;
        float dd_nod12 = dx12*dx12 + dy12*dy12 + dz12*dz12;

        if (dd_nod12 <= d_max_node){

            float x1,y1,z1,x2,y2,z2;
            float d, ds = ((float)(bn))/dmax, dd_max=dmax*dmax;
            int bin, end1=nodeD[idx1].end, end2=nodeR[idx2].end;
            double v;

            for (int i=nodeD[idx1].start; i<end1; ++i){
                x1 = elementsD[i].x;
                y1 = elementsD[i].y;
                z1 = elementsD[i].z;
                for (int j=nodeR[idx2].start; j<end2; ++j){
                    x2 = elementsR[j].x;
                    y2 = elementsR[j].y;
                    z2 = elementsR[j].z;
                    d = (x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)+(z2-z1)*(z2-z1);
                    if (d<=dd_max && d>0){
                        bin = (int)(sqrtf(d)*ds);
                        v = elementsD[i].w*elementsR[j].w;
                        atomicAdd(&XY[bin],v);
                    }
                }
            }
        }
    }
}
