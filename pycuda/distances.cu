#include<iostream>
#include<fstream>
#include<string.h>

#include <stdio.h>
#include <math.h>

using namespace std;

//Structura que define un punto 3D
//Accesa a cada componente con var.x, var.y, var.z
struct Punto{
    double x,y,z;
};

void read_file(string file_loc, Punto *data){
    cout << file_loc << endl;
    string line; //No uso esta variable realmente, pero con eof() no se detenía el loop
    
    ifstream archivo(file_loc);
    
    if (archivo.fail() | !archivo ){
        cout << "Error al cargar el archivo " << endl;
        exit(1);
    }
    
    
    int n_line = 1;
    if (archivo.is_open() && archivo.good()){
        archivo >> data[0].x >> data[0].y >> data[0].z;
        while(getline(archivo, line)){
            archivo >> data[n_line].x >> data[n_line].y >> data[n_line].z;
            n_line++;
        }
    }
    //cout << "Succesfully readed " << file_loc << endl;
}

void guardar_Histograma(string nombre,int dim, long int *histograma){
    ofstream archivo;
    archivo.open(nombre.c_str(),ios::out | ios::binary);
    if (archivo.fail()){
        cout << "Error al guardar el archivo " << endl;
        exit(1);
    }
    for (int i = 0; i < dim; i++)
    {
        archivo << histograma[i] << endl;
    }
    archivo.close();
}

float distance(Punto p1, Punto p2){
    float x = p1.x-p2.x, y=p1.y-p2.y, z=p1.z-p2.z;
    return sqrt(x*x + y*y + z*z);
}

__global__
void XY(float *dest, float *a, float *b, int *N){
    int p_id = threadIdx.x + blockDim.x*blockIdx.x;
    int id = threadIdx.y + blockDim.y*blockIdx.y;

    if (id < *N && p_id <*N){
        int x = id*3;
        int y = x+1;
        int z = y+1;

        int p_x = p_id*3;
        int p_y = p_x+1;
        int p_z = p_y+1;
        float d;
        //float histo[30];
        int bin;
        d = sqrt(pow(a[p_x] - b[x],2)+pow(a[p_y]-b[y],2) + pow(a[p_z]-b[z],2));
        if (d<=180){
            bin = (int) (d/6.0);
            atomicAdd(&dest[bin],1);
        }
    }
}

__global__
void XX(float *dest, float *a, int *N){
    int p_id = threadIdx.x + blockDim.x*blockIdx.x;
    int id = threadIdx.y + blockDim.y*blockIdx.y;

    if (p_id<*N && id<*N && p_id<id){

        int p_x = p_id*3;
        int p_y = p_x+1;
        int p_z = p_y+1;

        float d;
        int bin;

        int x = id*3;
        int y = x+1;
        int z = y+1;

        d = sqrt(pow(a[p_x] - a[x],2)+pow(a[p_y]-a[y],2) + pow(a[p_z]-a[z],2));
        if (d<=180){
            bin = (int) (d/6.0);
            atomicAdd(&dest[bin],2);
        }
    }
}

int main(int argc, char **argv){
        
    string data_loc = argv[1];
    string rand_loc = argv[2];
    string mypathto_files = "../fake_DATA/DATOS/";
    //This creates the full path to where I have my data files
    data_loc.insert(0,mypathto_files);
    rand_loc.insert(0,mypathto_files);
    
    unsigned int N = stoi(argv[3]), bins=stoi(argv[4]);
    unsigned int N_even = N+(N%2!=0);
    float d_max=stof(argv[5]);
    Punto *data = new Punto[N]; //Crea un array de N puntos
    Punto *rand = new Punto[N]; //Crea un array de N puntos

    //Llama a una funcion que lee los puntos y los guarda en la memoria asignada a data y rand
    read_file(data_loc,data);
    read_file(rand_loc,rand);

    // Crea los histogramas
    long int *DD, *DR, *RR;
    DD = new long int[bins];
    DR = new long int[bins];
    RR = new long int[bins];
    //Inicializa en 0
    for (int i=0; i<bins; i++){
        DD[i] = 0.0, RR[i] = 0.0, DR[i] = 0.0;     
    }
    double dbin = d_max/(double)bins;

    int threads=1, blocks=N_even, threads_test, blocks_test;
    float score=pow(blocks,2)+pow((blocks*threads)-N_even,2), score_test;

    for (int i=1; i<6; i++){
        threads_test = 2**i;
        blocks_test = (int)(N_even/threads_test)+1;
        score_test = pow(blocks_test,2)+pow((blocks_test*threads_test)-N_even,2);

        cout << threads_test << ',' << blocks_test << ',' << score_test << endl;
        
        if (score_test<score){
            threads=threads_test;
            blocks=blocks_test;
            score=score_test;
        }

    cout << threads << ',' << blocks << ',' << score << endl;

    return 0;
}