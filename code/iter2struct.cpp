#include "mex.h"
#include "matrix.h"
#include <numeric>
#include <algorithm>
#include <cstring>

static mxArray *indexer = NULL;
static mxArray *gridIter = NULL;
static mwSize *sizes = NULL;
static char **names = NULL;
static double *pIndex = NULL;
static mwSize nDims = 0;

static void setStructFields(mxArray *result, mwSize iTarget, mwSize iSource)
{
    if (pIndex == NULL)
    {
        const char *fieldNames[] = {"type", "subs"};
        mxArray *index = mxCreateDoubleScalar(1);
        mxArray *subs = mxCreateCellMatrix(1, 2);
        mxSetCell(subs, 0, mxCreateString(":"));
        mxSetCell(subs, 1, index);
        indexer = mxCreateStructMatrix(1, 1, 2, fieldNames);
        mxSetFieldByNumber(indexer, 0, 0, mxCreateString("()"));
        mxSetFieldByNumber(indexer, 0, 1, subs);
        pIndex = mxGetPr(index);
        mexMakeArrayPersistent(indexer);
    }

    for (mwSize iDim = 0; iDim < nDims; iDim++)
    {
        mxArray *iter = mxGetCell(gridIter, iDim);
        mxArray *value = NULL;
        mwSize i = iSource % sizes[iDim];
        bool isRow = mxGetM(iter) == 1;

        if (mxIsNumeric(iter))
        {
            void *data = mxGetData(iter);
            mwSize nRows = mxGetM(iter);
            mwSize offset = i * nRows;
            mwSize nBytes = mxGetElementSize(iter);
            value = mxCreateNumericMatrix(nRows, 1, mxGetClassID(iter), mxREAL);
            memcpy(mxGetData(value), static_cast<char *>(data) + offset * nBytes, nRows * nBytes);
        }
        else if (isRow && mxIsStruct(iter))
        {
            mwSize nFields = mxGetNumberOfFields(iter);
            const char **names = new const char *[nFields];
            for (mwSize iField = 0; iField < nFields; iField++)
            {
                names[iField] = mxGetFieldNameByNumber(iter, iField);
            }
            value = mxCreateStructMatrix(1, 1, nFields, names);
            for (mwSize iField = 0; iField < nFields; iField++)
            {
                mxSetFieldByNumber(value, 0, iField, mxDuplicateArray(mxGetFieldByNumber(iter, i, iField)));
            }
        }
        else if (isRow && mxIsChar(iter))
        {
            mxChar *str = mxGetChars(iter);
            mwSize sizes[] = {1};
            value = mxCreateCharArray(1, sizes);
            mxGetChars(value)[0] = str[i];
        }
        else
        {
            *pIndex = i + 1;
            mxArray *args[] = {iter, indexer};
            mexCallMATLAB(1, &value, 2, args, "subsref");
        }

        mxSetFieldByNumber(result, iTarget, iDim, value);
        iSource /= sizes[iDim];
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // load meta data
    if (nrhs > 1)
    {
        if (gridIter != NULL)
        {
            mxDestroyArray(gridIter);
            std::for_each(names, names + nDims, mxFree);
            delete[] names;
            delete[] sizes;
        }

        gridIter = mxDuplicateArray(prhs[0]);
        mexMakeArrayPersistent(gridIter);
        nDims = mxGetNumberOfElements(prhs[0]);
        sizes = new mwSize[nDims];
        names = new char *[nDims];
        for (mwSize iDim = 0; iDim < nDims; iDim++)
        {
            sizes[iDim] = mxGetN(mxGetCell(prhs[0], iDim));
            names[iDim] = mxArrayToString(mxGetCell(prhs[1], iDim));
            mexMakeMemoryPersistent(names[iDim]);
        }
    }
    else if (gridIter == NULL)
    {
        mexErrMsgIdAndTxt("grid:InvalidInput", "No grid iterator loaded.");
    }

    // create single struct
    if (nrhs == 1 || nrhs == 3)
    {
        plhs[0] = mxCreateStructMatrix(1, 1, nDims, const_cast<const char **>(names));
        setStructFields(plhs[0], 0, mxGetScalar(prhs[nrhs - 1]));
    }

    // create struct array
    else if (nlhs > 0)
    {
        mwSize nTotal(std::accumulate(sizes, sizes + nDims, 1, [](mwSize a, mwSize b) { return a * b; }));
        plhs[0] = mxCreateStructMatrix(nTotal, 1, nDims, const_cast<const char **>(names));
        for (mwSize k = 0; k < nTotal; k++)
        {
            setStructFields(plhs[0], k, k);
        }
    }
}