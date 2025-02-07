#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <vector>

using namespace std;

void merge(vector<int>& arr, int begin, int mid, int endrt)
{
    int Lsz = mid - begin + 1;
    int Rsz = endrt - mid;

    // cout << "merge #%#: " << begin << "  mid: " << mid << "  end: " << endrt << endl;
    // cout << "Lsz:  " << Lsz << "   Rsz: "<< Rsz << endl;

    vector<int> left(Lsz), right(Rsz); // temp vectors

    for (int i = 0; i < Lsz; i++)
        left[i] = arr[begin + i];
    for (int j = 0; j < Rsz; j++)
        right[j] = arr[mid + 1 + j];

    int i = 0, j = 0;
    int k = begin;

    // merge the sorted elements back into arr
    while (i < Lsz && j < Rsz)
    {
        if (left[i] <= right[j])
        {
            arr[k] = left[i];
            i++;
        }
        else
        {
            arr[k] = right[j];
            j++;
        }
        k++;
    }

    // copy the remaining elements of left and right to arr
    while (i < Lsz)
    {
        arr[k] = left[i];
        i++;
        k++;
    }
    while (j < Rsz)
    {
        arr[k] = right[j];
        j++;
        k++;
    }
}

void merge_sort(vector<int>& arr, int begin, int end)
{
    if (begin >= end)
        return;
    // cout << "ms###: " << begin << "  end: " << end << endl;
    int mid = (begin + end) / 2;
    merge_sort(arr, begin, mid);
    merge_sort(arr, mid + 1, end);
    merge(arr, begin, mid, end);
}

void printarray(vector<int>& v)
{
    for (int i = 0; i < v.size(); i++)
    {
        cout << v[i] << " ";
    }
    cout << endl;
}

int main(int argc, char *argv[])
{
    cout << "Hello merge-sort" << endl;

    if (argc < 2) {
        std::cerr << "require argument for array size" << std::endl;
        return 1;
    }

    int inp_size = std::atoi(argv[1]);

    if (inp_size <= 0) {
        cerr << "Array size must be a positive integer." << std::endl;
        return 1;
    }

    // inp_size = 12;

    vector<int> inp_arr(inp_size);

    for (int i = 0; i < inp_size; ++i)
    {
        inp_arr[i] = rand();
    }
    // cout << "Before sorting: " << endl;
    // printarray(inp_arr);

    merge_sort(inp_arr, 0, inp_size - 1);
    cout << "completed merge sort for array size of: " << inp_size << endl;

    // cout << "After sorting: " << endl;
    // printarray(inp_arr);

    return 0;
}