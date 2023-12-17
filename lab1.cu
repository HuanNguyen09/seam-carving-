#include <stdio.h>
#include <stdint.h>

#define FILTER_rows 9
__constant__ float dc_filter[FILTER_rows * FILTER_rows];

#define CHECK(call)\
{\
    const cudaError_t error = call;\
    if (error != cudaSuccess)\
    {\
        fprintf(stderr, "Error: %s:%d, ", __FILE__, __LINE__);\
        fprintf(stderr, "code: %d, reason: %s\n", error,\
                cudaGetErrorString(error));\
        exit(EXIT_FAILURE);\
    }\
}

struct GpuTimer
{
    cudaEvent_t start;
    cudaEvent_t stop;

    GpuTimer()
    {
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
    }

    ~GpuTimer()
    {
        cudaEventDestroy(start);
        cudaEventDestroy(stop);
    }

    void Start()
    {
        cudaEventRecord(start, 0);
        cudaEventSynchronize(start);
    }

    void Stop()
    {
        cudaEventRecord(stop, 0);
    }

    float Elapsed()
    {
        float elapsed;
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&elapsed, start, stop);
        return elapsed;
    }
};

void readPnm(char * fileName, int &rows, int &columns, uchar3 * &pixels)
{
	FILE * f = fopen(fileName, "r");
	if (f == NULL)
	{
		printf("Cannot read %s\n", fileName);
		exit(EXIT_FAILURE);
	}

	char type[3];
	fscanf(f, "%s", type);
	
	if (strcmp(type, "P3") != 0) // In this exercise, we don't touch other types
	{
		fclose(f);
		printf("Cannot read %s\n", fileName); 
		exit(EXIT_FAILURE); 
	}

	fscanf(f, "%i", &rows);
	fscanf(f, "%i", &columns);
	
	int max_val;
	fscanf(f, "%i", &max_val);
	if (max_val > 255) // In this exercise, we assume 1 byte per value
	{
		fclose(f);
		printf("Cannot read %s\n", fileName); 
		exit(EXIT_FAILURE); 
	}

	pixels = (uchar3 *)malloc(rows * columns * sizeof(uchar3));
	for (int i = 0; i < rows * columns; i++)
		fscanf(f, "%hhu%hhu%hhu", &pixels[i].x, &pixels[i].y, &pixels[i].z);

	fclose(f);
}

void writePnm(uchar3 * pixels, int rows, int columns, char * fileName)
{
	FILE * f = fopen(fileName, "w");
	if (f == NULL)
	{
		printf("Cannot write %s\n", fileName);
		exit(EXIT_FAILURE);
	}	

	fprintf(f, "P3\n%i\n%i\n255\n", rows, columns); 

	for (int i = 0; i < rows * columns; i++)
		fprintf(f, "%hhu\n%hhu\n%hhu\n", pixels[i].x, pixels[i].y, pixels[i].z);
	
	fclose(f);
}

// __global__ void blurImgKernel1(uchar3 * inPixels, int rows, int columns, 
//         float * filter, int filterrows, 
//         uchar3 * outPixels)
// {
// 	// TODO

// }

// __global__ void blurImgKernel2(uchar3 * inPixels, int rows, int columns, 
//         float * filter, int filterrows, 
//         uchar3 * outPixels)
// {
// 	// TODO

// }

// __global__ void blurImgKernel3(uchar3 * inPixels, int rows, int columns, 
//         int filterrows, 
//         uchar3 * outPixels)
// {
// 	// TODO

// }							
void rgbToGray(uchar3 *pixels, int rows, int columns, unsigned char *&grayPixels) {
    grayPixels = (unsigned char *)malloc(rows * columns * sizeof(unsigned char));

    for (int i = 0; i < rows * columns; i++) {
        // Chuyển đổi thành giá trị gray theo công thức cụ thể
        grayPixels[i] = (unsigned char)(0.299 * pixels[i].x + 0.587 * pixels[i].y + 0.114 * pixels[i].z);
    }
}
void writePnmGray(char *fileName, int rows, int columns, unsigned char *grayPixels) {
    FILE *f = fopen(fileName, "w");
    if (f == NULL) {
        printf("Cannot write %s\n", fileName);
        exit(EXIT_FAILURE);
    }

    fprintf(f, "P2\n");
    fprintf(f, "%d %d\n", rows, columns);
    fprintf(f, "255\n");

    for (int i = 0; i < rows * columns; i++) {
        fprintf(f, "%d\n", grayPixels[i]);
    }

    fclose(f);
}

void convolveX(unsigned char *inputPixels, int rows, int columns, unsigned char *&outputPixels) {
    // Sobel filter for x-direction
    int sobelFilter[3][3] = {{1, 0, -1}, {2, 0, -2}, {1, 0, -1}};

    outputPixels = (unsigned char *)malloc(rows * columns * sizeof(unsigned char));

    // Convolution
    for (int y = 1; y < columns - 1; y++) {
        for (int x = 1; x < rows - 1; x++) {
            int sum = 0;
            for (int i = -1; i <= 1; i++) {
                for (int j = -1; j <= 1; j++) {
                    sum += sobelFilter[i + 1][j + 1] * inputPixels[(y + i) * rows + (x + j)];
                }
            }
            // Ensure the result is within the valid range [0, 255]
            outputPixels[y * rows + x] = (unsigned char)(sum > 255 ? 255 : (sum < 0 ? 0 : sum));
        }
    }
}

void convolveY(unsigned char *inputPixels, int rows, int columns, unsigned char *&outputPixels) {
    // Sobel filter for y-direction
    int sobelFilter[3][3] = {{1, 2, 1}, {0, 0, 0}, {-1, -2, -1}};

    outputPixels = (unsigned char *)malloc(rows * columns * sizeof(unsigned char));

    // Convolution
    for (int y = 1; y < columns - 1; y++) {
        for (int x = 1; x < rows - 1; x++) {
            int sum = 0;
            for (int i = -1; i <= 1; i++) {
                for (int j = -1; j <= 1; j++) {
                    sum += sobelFilter[i + 1][j + 1] * inputPixels[(y + i) * rows + (x + j)];
                }
            }
            // Ensure the result is within the valid range [0, 255]
            outputPixels[y * rows + x] = (unsigned char)(sum > 255 ? 255 : (sum < 0 ? 0 : sum));
        }
    }
}

void calculateImportance(unsigned char *edgesX, unsigned char *edgesY, int rows, int columns, unsigned char *&importance) {
    importance = (unsigned char *)malloc(rows * columns * sizeof(unsigned char));

    for (int i = 0; i < rows * columns; i++) {
        importance[i] = abs(edgesX[i]) + abs(edgesY[i]);
    }
}

int findMinOfThree(int a, int b, int c) {
    int minValue = a;

    if (b < minValue) {
        minValue = b;
    }

    if (c < minValue) {
        minValue = c;
    }

    return minValue;
}

unsigned char findMin(unsigned char *energy, int rows, int columns, int i, int j) {
    unsigned char min = 255;
    unsigned char a = 255;
    unsigned char b = energy[(i + 1) * columns + j];
    unsigned char c = 255;
    if (j == 0) {
        c = energy[(i + 1) * columns + j + 1];
    } else if (j == columns - 1) {
        a = energy[(i + 1) * columns + j - 1];
    } else {
        a = energy[(i + 1) * columns + j - 1];
        c = energy[(i + 1) * columns + j + 1];
    }
    if (min > findMinOfThree(a, b, c))
        min = findMinOfThree(a, b, c);
    return min;
}

int findIndex(unsigned char *M, int rows, int columns, int i, int k) {
    unsigned char min = 255;
    unsigned char a = 255;
    unsigned char b = M[(i) * columns + k];
    unsigned char c = 255;
    if (k == 0) {
        c = M[(i) * columns + k + 1];
    } else if (k == columns - 1) {
        a = M[(i) * columns + k - 1];
    } else {
        a = M[(i) * columns + k - 1];
        c = M[(i) * columns + k + 1];
    }
    if (min > findMinOfThree(a, b, c))
        min = findMinOfThree(a, b, c);
    for (int h = k - 1; h <= k + 1; h++)
        if (min == M[i * columns + h])
            return h;
  return -1;
}

void findOptSeam(unsigned char *energy, int rows, int columns, unsigned char *optSeamMask) {
    unsigned char *M = (unsigned char *)malloc(rows * columns * sizeof(unsigned char));
    optSeamMask = (unsigned char *)malloc(rows * columns * sizeof(unsigned char));
    memset(optSeamMask, 0, rows * columns * sizeof(unsigned char));

    // Least pixel-importance to bottom
    for (int j = 0; j < columns; j++)
        M[(rows - 1) * columns + j] = energy[(rows - 1) * columns + j];

    for (int i = rows - 2; i >= 0; i--)
        for (int j = columns - 1; j >= 0; j--) {
            M[i * columns + j] = energy[i * columns + j] + findMin(M, rows, columns, i, j);
        }

    //
    unsigned char min = M[0];
    for (int j = 0; j < columns; j++) {
        if (min > M[j])
            min = M[j];
    }
    int k = -1;
    for (int j = 0; j < columns; j++) {
        if (min == M[j])
            k = j;
    }
    optSeamMask[k] = 1;
    for (int i = 1; i < rows; i++) {
        k = findIndex(M, rows, columns, i, k);
        optSeamMask[i * columns + k] = 1;
    }

    for (int i = 0; i < rows; ++i) {
        for (int j = 0; j < columns; ++j) {
            printf("%3d ", M[i * columns + j]);
        }
        printf("\n");
    }

    free(M);
}

void removeSeam(uchar3 *energyMatrix, unsigned char *seamMask, int rows, int columns) {
    // Copy giá trị từ ma trận cũ sang ma trận mới, bỏ qua các cột được đánh dấu trong seamMask
    for (int i = 0; i < rows; ++i) {
        int newColIndex = 0;
        for (int j = 0; j < columns; ++j) {
            if (seamMask[i * columns + j] == 0) {
                energyMatrix[i * (columns - 1) + newColIndex] = energyMatrix[i * columns + j];
                ++newColIndex;
            }
        }
    }
}



void seamCarvingImage(uchar3 *energyMatrix, uchar3 *newEnergyMatrix, int rows, int columns, int n)
{
  for(int k=0; k<n; k++)
  {
    
    unsigned char *grayPixels, *edgesX, *edgesY, *importance, *optSeamMaskMatrix;
    // Chuyển đổi từ ảnh RGB sang grayscale

    rgbToGray(energyMatrix, rows, columns, grayPixels);
    convolveX(grayPixels, rows, columns, edgesX);
    // Convolve with y-Sobel filter
    convolveY(grayPixels, rows, columns, edgesY);
    calculateImportance(edgesX, edgesY, rows, columns, importance);

    // Tạo mảng để lưu kết quả
    
    
    // Gọi hàm findOptSeam
    findOptSeam(importance, rows, columns, optSeamMaskMatrix);
    removeSeam(energyMatrix, optSeamMaskMatrix, rows, columns);

    free(grayPixels);
    free(edgesX);
    free(edgesY);
    free(importance);
    free(optSeamMaskMatrix);

    columns--;
  }
  newEnergyMatrix = (uchar3 *)malloc((rows) * (columns-n) * sizeof(uchar3));
  for(int i=0; i<rows;i++)
    for(int j=0; j<columns-n; j++)
      newEnergyMatrix[i*columns+j]=energyMatrix[i*columns+j];
  return ;
}



void blurImg(uchar3 * inPixels, int rows, int columns, float * filter, int filterrows, 
        uchar3 * outPixels,
        bool useDevice=false, dim3 blockSize=dim3(1, 1), int kernelType=1)
{
	if (useDevice == false)
	{
		// for (int r = 0; r < columns; r++)
    //     {
    //         for (int c = 0; c < rows; c++)
    //         {
    //             int i = r * rows + c;
    //             outPixels[i] = 0.299f*inPixels[3 * i] + 0.587f*inPixels[3 * i + 1] + 0.114f*inPixels[3 * i + 2];
    //         }
    //     }
	}
	// else // Use device
	// {
	// 	GpuTimer timer;
		
	// 	printf("\nKernel %i, ", kernelType);
	// 	// Allocate device memories
	// 	uchar3 * d_inPixels, * d_outPixels;
	// 	float * d_filter;
	// 	size_t pixelsSize = rows * columns * sizeof(uchar3);
	// 	size_t filterSize = filterrows * filterrows * sizeof(float);
	// 	CHECK(cudaMalloc(&d_inPixels, pixelsSize));
	// 	CHECK(cudaMalloc(&d_outPixels, pixelsSize));
	// 	if (kernelType == 1 || kernelType == 2)
	// 	{
	// 		CHECK(cudaMalloc(&d_filter, filterSize));
	// 	}

	// 	// Copy data to device memories
	// 	CHECK(cudaMemcpy(d_inPixels, inPixels, pixelsSize, cudaMemcpyHostToDevice));
	// 	if (kernelType == 1 || kernelType == 2)
	// 	{
	// 		CHECK(cudaMemcpy(d_filter, filter, filterSize, cudaMemcpyHostToDevice));
	// 	}
	// 	else
	// 	{
	// 		// TODO: copy data from "filter" (on host) to "dc_filter" (on CMEM of device)

	// 	}

	// 	// Call kernel
	// 	dim3 gridSize((rows-1)/blockSize.x + 1, (columns-1)/blockSize.y + 1);
	// 	printf("block size %ix%i, grid size %ix%i\n", blockSize.x, blockSize.y, gridSize.x, gridSize.y);
	// 	timer.Start();
	// 	if (kernelType == 1)
	// 	{
	// 		// TODO: call blurImgKernel1

	// 	}
	// 	else if (kernelType == 2)
	// 	{
	// 		// TODO: call blurImgKernel2

	// 	}
	// 	else
	// 	{
	// 		// TODO: call blurImgKernel3

	// 	}
	// 	timer.Stop();
	// 	float time = timer.Elapsed();
	// 	printf("Kernel time: %f ms\n", time);
	// 	cudaDeviceSynchronize();
	// 	CHECK(cudaGetLastError());

	// 	// Copy result from device memory
	// 	CHECK(cudaMemcpy(outPixels, d_outPixels, pixelsSize, cudaMemcpyDeviceToHost));

	// 	// Free device memories
	// 	CHECK(cudaFree(d_inPixels));
	// 	CHECK(cudaFree(d_outPixels));
	// 	if (kernelType == 1 || kernelType == 2)
	// 	{
	// 		CHECK(cudaFree(d_filter));
	// 	}
	// }
	
}

float computeError(uchar3 * a1, uchar3 * a2, int n)
{
	float err = 0;
	for (int i = 0; i < n; i++)
	{
		err += abs((int)a1[i].x - (int)a2[i].x);
		err += abs((int)a1[i].y - (int)a2[i].y);
		err += abs((int)a1[i].z - (int)a2[i].z);
	}
	err /= (n * 3);
	return err;
}

void printError(uchar3 * deviceResult, uchar3 * hostResult, int rows, int columns)
{
	float err = computeError(deviceResult, hostResult, rows * columns);
	printf("Error: %f\n", err);
}

char * concatStr(const char * s1, const char * s2)
{
    char * result = (char *)malloc(strlen(s1) + strlen(s2) + 1);
    strcpy(result, s1);
    strcat(result, s2);
    return result;
}

void printDeviceInfo()
{
	cudaDeviceProp devProv;
    CHECK(cudaGetDeviceProperties(&devProv, 0));
    printf("**********GPU info**********\n");
    printf("Name: %s\n", devProv.name);
    printf("Compute capability: %d.%d\n", devProv.major, devProv.minor);
    printf("Num SMs: %d\n", devProv.multiProcessorCount);
    printf("Max num threads per SM: %d\n", devProv.maxThreadsPerMultiProcessor); 
    printf("Max num warps per SM: %d\n", devProv.maxThreadsPerMultiProcessor / devProv.warpSize);
    printf("GMEM: %lu bytes\n", devProv.totalGlobalMem);
    printf("CMEM: %lu bytes\n", devProv.totalConstMem);
    printf("L2 cache: %i bytes\n", devProv.l2CacheSize);
    printf("SMEM / one SM: %lu bytes\n", devProv.sharedMemPerMultiprocessor);
    printf("****************************\n");

}

int main(int argc, char ** argv)
{
	if (argc !=3 && argc != 5)
	{
		printf("The number of arguments is invalid\n");
		return EXIT_FAILURE;
	}

	printDeviceInfo();

	// Read input image file
	int rows, columns;
	uchar3 * inPixels, *outPixels;
	readPnm(argv[1], rows, columns, inPixels);
	printf("\nImage size (rows x columns): %i x %i\n", rows, columns);

  seamCarvingImage(inPixels, outPixels, rows, columns, 100);
  char * outFileNameBase = strtok(argv[2], "."); // Get rid of extension
  writePnm(outPixels, rows, columns-100, concatStr(outFileNameBase, "_host.pnm"));

  // unsigned char *grayPixels, *edgesX,*edgesY;
  // unsigned char *importance;
  // // Chuyển đổi từ ảnh RGB sang grayscale
  // rgbToGray(inPixels, rows, columns, grayPixels);

  // // Write results to files
  //   char * outFileNameBase = strtok(argv[2], "."); // Get rid of extension
  //   // Ghi ảnh grayscale vào file

  // convolveX(grayPixels, rows, columns, edgesX);
  // // Convolve with y-Sobel filter
  //   convolveY(grayPixels, rows, columns, edgesY);
  //   calculateImportance(edgesX, edgesY, rows, columns, importance);
  // writePnmGray(concatStr(outFileNameBase, "X_host.pnm"), rows, columns, edgesX);
  // writePnmGray(concatStr(outFileNameBase, "Y_host.pnm"), rows, columns, edgesY);
  // writePnmGray(concatStr(outFileNameBase, "importance_host.pnm"), rows, columns, (unsigned char *)importance);




// 	// Set up a simple filter with blurring effect 
// 	int filterrows = FILTER_rows;
// 	float * filter = (float *)malloc(filterrows * filterrows * sizeof(float));
// 	for (int filterR = 0; filterR < filterrows; filterR++)
// 	{
// 		for (int filterC = 0; filterC < filterrows; filterC++)
// 		{
// 			filter[filterR * filterrows + filterC] = 1. / (filterrows * filterrows);
// 		}
// 	}

// 	// Blur input image not using device
// 	uchar3 * correctOutPixels = (uchar3 *)malloc(rows * columns * sizeof(uchar3)); 
// 	blurImg(inPixels, rows, columns, filter, filterrows, correctOutPixels);
	
//     // Blur input image using device, kernel 1
//     dim3 blockSize(16, 16); // Default
// 	if (argc == 5)
// 	{
// 		blockSize.x = atoi(argv[3]);
// 		blockSize.y = atoi(argv[4]);
// 	}	
// // 	uchar3 * outPixels1 = (uchar3 *)malloc(rows * columns * sizeof(uchar3));
// // 	blurImg(inPixels, rows, columns, filter, filterrows, outPixels1, true, blockSize, 1);
// // 	printError(outPixels1, correctOutPixels, rows, columns);
	
// // 	// Blur input image using device, kernel 2
// // 	uchar3 * outPixels2 = (uchar3 *)malloc(rows * columns * sizeof(uchar3));
// // 	blurImg(inPixels, rows, columns, filter, filterrows, outPixels2, true, blockSize, 2);
// // 	printError(outPixels2, correctOutPixels, rows, columns);
// // ``
// // 	// Blur input image using device, kernel 3
// // 	uchar3 * outPixels3 = (uchar3 *)malloc(rows * columns * sizeof(uchar3));
// // 	blurImg(inPixels, rows, columns, filter, filterrows, outPixels3, true, blockSize, 3);
// // 	printError(outPixels3, correctOutPixels, rows, columns);

//     // Write results to files
//     char * outFileNameBase = strtok(argv[2], "."); // Get rid of extension
// 	writePnm(correctOutPixels, rows, columns, concatStr(outFileNameBase, "_host.pnm"));
// 	// writePnm(outPixels1, rows, columns, concatStr(outFileNameBase, "_device1.pnm"));
// 	// writePnm(outPixels2, rows, columns, concatStr(outFileNameBase, "_device2.pnm"));
// 	// writePnm(outPixels3, rows, columns, concatStr(outFileNameBase, "_device3.pnm"));

// 	// Free memories
// 	free(inPixels);
// 	free(filter);
// 	free(correctOutPixels);
// 	// free(outPixels1);
// 	// free(outPixels2);
// 	// free(outPixels3);
}

