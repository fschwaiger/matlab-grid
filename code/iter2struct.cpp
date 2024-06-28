#include "mex.hpp"
#include "mexAdapter.hpp"
#include <vector>

using namespace std;
using namespace matlab::data;
using namespace matlab::engine;

class MexFunction : public matlab::mex::Function
{
public:
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs)
    {
        CellArray gridIter(inputs[0]);
        StringArray gridDims(inputs[1]);
        auto nDims = gridIter.getNumberOfElements();
        auto names = vector<string>(nDims);
        auto sizes = vector<size_t>(nDims);
        size_t nTotal = 1;

        for (size_t i = 0, n = 0; i < nDims; i++)
        {
            n = gridIter[i].getDimensions()[1];
            names[i] = gridDims[i];
            sizes[i] = n;
            nTotal *= n;
        }

        if (inputs.size() == 3)
        {
            auto result(factory.createStructArray({1, 1}, names));
            setStructFields(result, gridIter, sizes, names, 0, size_t(inputs[2][0]) - 1);
            outputs[0] = result;
        }
        else
        {
            auto result(factory.createStructArray({nTotal, 1}, names));
            for (size_t k = 0; k < nTotal; k++)
            {
                setStructFields(result, gridIter, sizes, names, k, k);
            }
            outputs[0] = result;
        }
    }

    MexFunction() : substructure(factory.createStructArray({1, 1}, {"type", "subs"}))
    {
        engine = getEngine();
        auto subs(factory.createCellArray({1, 2}));
        subs[0] = factory.createCharArray(":");
        subs[1] = factory.createScalar<double>(0);
        substructure[0]["type"] = factory.createCharArray("()");
        substructure[0]["subs"] = subs;
    }

private:
    ArrayFactory factory;
    shared_ptr<MATLABEngine> engine;
    StructArray substructure;

    void setStructFields(StructArray &result, const CellArray &iters,
        const vector<size_t> &sizes, const vector<string> &names,
        size_t iTarget, size_t iSource)
    {
        Array itDim, slice;
        size_t iCol;
        for (size_t iDim = 0; iDim < sizes.size(); iDim++)
        {
            itDim = iters[iDim];
            iCol = iSource % sizes[iDim];
            iSource /= sizes[iDim];

            if (itDim.getType() == ArrayType::DOUBLE)
            {
                slice = sliceArray<double>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::LOGICAL)
            {
                slice = sliceArray<bool>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::CHAR)
            {
                slice = sliceArray<char16_t>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::MATLAB_STRING)
            {
                slice = sliceArray<MATLABString>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::UINT8)
            {
                slice = sliceArray<uint8_t>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::INT8)
            {
                slice = sliceArray<int8_t>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::UINT16)
            {
                slice = sliceArray<uint16_t>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::INT16)
            {
                slice = sliceArray<int16_t>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::UINT32)
            {
                slice = sliceArray<uint32_t>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::INT32)
            {
                slice = sliceArray<int32_t>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::UINT64)
            {
                slice = sliceArray<uint64_t>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::INT64)
            {
                slice = sliceArray<int64_t>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::COMPLEX_DOUBLE)
            {
                slice = sliceArray<complex<double>>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::COMPLEX_SINGLE)
            {
                slice = sliceArray<complex<float>>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::COMPLEX_INT8)
            {
                slice = sliceArray<complex<int8_t>>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::COMPLEX_UINT8)
            {
                slice = sliceArray<complex<uint8_t>>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::COMPLEX_INT16)
            {
                slice = sliceArray<complex<int16_t>>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::COMPLEX_UINT16)
            {
                slice = sliceArray<complex<uint16_t>>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::COMPLEX_INT32)
            {
                slice = sliceArray<complex<int32_t>>(itDim, iCol);
            }
            else if (itDim.getType() == ArrayType::COMPLEX_UINT32)
            {
                slice = sliceArray<complex<uint32_t>>(itDim, iCol);
            }
            else
            {
                CellArrayRef subs = substructure[0]["subs"];
                subs[1] = factory.createScalar<double>(iCol + 1);
                slice = engine->feval(u"subsref", 1, {itDim, substructure}).front();
            }

            result[iTarget][names[iDim]] = slice;
        }
    }

    template <typename T>
    inline TypedArray<T> sliceArray(const TypedArray<T> &iter, size_t k)
    {
        auto nRows = iter.getDimensions()[0];
        auto first = iter.begin() + (k * nRows);
        auto last = first + nRows;
        return factory.createArray({nRows, 1}, first, last);
    }
};

// %#release exclude file
