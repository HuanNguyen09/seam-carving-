// #include <stdio.h>
// #include <stdlib.h>
// #include <stdint.h>

// int findMinOfThree(int a, int b, int c) {
//     int minValue = a;

//     if (b < minValue) {
//         minValue = b;
//     }

//     if (c < minValue) {
//         minValue = c;
//     }

//     return minValue;
// }

// unsigned char findMin(unsigned char *energy, int rows, int columns, int i, int j){
//     unsigned char min = 255;
//     unsigned char a = 255;
//     unsigned char b = energy[(i+1)*columns +j];
//     unsigned char c = 255;
//     if (j==0){
//         c = energy[(i+1)*columns +j+1];
//     }else if (j==columns-1){
//         a = energy[(i+1)*columns +j-1];
//     } else{
//         a = energy[(i+1)*columns +j-1];
//         c = energy[(i+1)*columns +j+1];
//     }
//     if ( min > findMinOfThree(a,b,c))
//         min = findMinOfThree(a,b,c);
//     return min;
// }

// int findIndex(unsigned char* M, int rows, int columns,int i, int k)
// {
//     unsigned char min = 255;
//     unsigned char a = 255;
//     unsigned char b = M[(i)*columns +k];
//     unsigned char c = 255;
//     if (k==0){
//         c = M[(i)*columns +k+1];
//     }else if (k==columns-1){
//         a = M[(i)*columns +k-1];
//     } else{
//         a = M[(i)*columns +k-1];
//         c = M[(i)*columns +k+1];
//     }
//     if ( min > findMinOfThree(a,b,c))
//         min = findMinOfThree(a,b,c);
//     for(int h=k-1; h<= k+1;h++)
//         if (min == M[i*columns+h])
//             return h;
// }

// void findOptSeam(unsigned char *energy, int rows, int columns, unsigned char *optSeamMask) {
//     unsigned char *M = (unsigned char *)malloc(rows * columns * sizeof(unsigned char));

//     // Least pixel-importance to bottom 
//     for(int j=0; j<columns;j++)
//       M[(rows-1)*columns + j]=energy[(rows-1)*columns + j];
    
//     for (int i= rows -2 ; i>=0; i--)
//       for(int j = columns -1; j>=0; j--)
//         {
//           M[i*columns + j]=energy[i*columns + j]+findMin(M, rows, columns, i, j);
//         }


//     //
//     unsigned char min = M[0];
//     for(int j=0; j<columns;j++)
//     {
//         if (min> M[j])
//         min=M[j];
//     }
//     int k = -1;
//     for(int j=0; j<columns;j++)
//     {
//         if (min == M[j])
//             k=j;
//     }
//     optSeamMask[k]=1;
//     for(int i=1; i<rows;i++)
//     {
//         k=findIndex(M,rows,columns,i,k);
//         optSeamMask[i*columns+k]=1;
//     }

//     for (int i = 0; i < rows; ++i) {
//         for (int j = 0; j < columns ; ++j) {
//             printf("%3d ", M[i * columns + j]);
//         }
//         printf("\n");
//     }
// }

// // void seamCarving(uchar3 *pixels,  int rows, int columns, int n)
// // {
// //     for(int k=0;k<n;k++){

// //     }

// // }
// void removeSeam(unsigned char *energyMatrix,unsigned char *newEnergyMatrix, unsigned char  *seamMask, int rows, int columns) {
//     // Copy giá trị từ ma trận cũ sang ma trận mới, bỏ qua các cột được đánh dấu trong seamMask
//     for (int i = 0; i < rows; ++i) {
//         int newColIndex = 0;
//         for (int j = 0; j < columns; ++j) {
//             if (seamMask[i * columns + j] == 0) {
//                 newEnergyMatrix[i*columns+newColIndex] = energyMatrix[i*columns+j];
//                 ++newColIndex;
//             }
//         }
//     }
// }
// int main() {
//     // Kích thước của ma trận
//     int rows = 3;
//     int columns = 5;

//     // Tạo ma trận energy (ví dụ: các giá trị ngẫu nhiên)
//     unsigned char energyMatrix[] = {
//         1, 4, 3, 5, 2,
//         3, 2, 5, 2, 3,
//         5, 3, 4, 2, 1
//     };

//     // Tạo mảng để lưu kết quả
//     unsigned char* optSeamMaskMatrix;
//     memset(optSeamMaskMatrix, 0, rows * columns * sizeof(unsigned char));

//     // Gọi hàm findOptSeam
//     findOptSeam(energyMatrix, rows, columns, optSeamMaskMatrix);
//     unsigned char *newEnergyMatrix = (unsigned char *)malloc(rows * (columns - 1) * sizeof(unsigned char));
//     removeSeam(energyMatrix, newEnergyMatrix, optSeamMaskMatrix, rows, columns);

//     // In kết quả
//     printf("Optimal Seam Mask:\n");
//     for (int i = 0; i < rows; ++i) {
//         for (int j = 0; j < columns; ++j) {
//             printf("%3d ", optSeamMaskMatrix[i * columns + j]);
//         }
//         printf("\n");
//     }

//     // In kết quả
//     printf("Optimal Seam Mask:\n");
//     for (int i = 0; i < rows; ++i) {
//         for (int j = 0; j < columns-1; ++j) {
//             printf("%3d ", newEnergyMatrix[i * columns + j]);
//         }
//         printf("\n");
//     }
//     return 0;
// }


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

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
}

void findOptSeam(unsigned char *energy, int rows, int columns, unsigned char *optSeamMask) {
    unsigned char *M = (unsigned char *)malloc(rows * columns * sizeof(unsigned char));

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

void removeSeam(unsigned char *energyMatrix, unsigned char *seamMask, int rows, int columns) {
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

// void seamCarvingImage(uchar3 *energyMatrix, uchar3 *newEnergyMatrix, int rows, int columns, int n)
// {
//     for(int k=0; k<n; k++)
//     {

//     }
// }
int main() {
    // Kích thước của ma trận
    int rows = 3;
    int columns = 5;

    // Tạo ma trận energy (ví dụ: các giá trị ngẫu nhiên)
    unsigned char energyMatrix[] = {
        1, 4, 3, 5, 2,
        3, 2, 5, 2, 3,
        5, 3, 4, 2, 1
    };

    // Tạo mảng để lưu kết quả
    unsigned char *optSeamMaskMatrix = (unsigned char *)malloc(rows * columns * sizeof(unsigned char));
    memset(optSeamMaskMatrix, 0, rows * columns * sizeof(unsigned char));

    // Gọi hàm findOptSeam
    findOptSeam(energyMatrix, rows, columns, optSeamMaskMatrix);
    removeSeam(energyMatrix, optSeamMaskMatrix, rows, columns);

    // In kết quả
    printf("Optimal Seam Mask:\n");
    for (int i = 0; i < rows; ++i) {
        for (int j = 0; j < columns; ++j) {
            printf("%3d ", optSeamMaskMatrix[i * columns + j]);
        }
        printf("\n");
    }

    // In kết quả
    printf("Updated energyMatrix:\n");
    for (int i = 0; i < rows; ++i) {
        for (int j = 0; j < columns - 1; ++j) {
            printf("%3d ", energyMatrix[i * (columns - 1) + j]);
        }
        printf("\n");
    }

    // Giải phóng bộ nhớ
    free(optSeamMaskMatrix);
    // free(newEnergyMatrix);

    return 0;
}
