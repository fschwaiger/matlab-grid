A grid container for MATLAB
===========================

The grid class is a fundamental part of passing test iterations from one testing stage to another in the [tico Toolbox](https://gitlab.com/tum-fsd/tico).
The core implementation of *tico* is independent of this, however it simplifies handling envelopes for the user.

Conceptually, `containers.Grid` relates to n-dimensional matrices like a *MATLAB* `table` relates to a 2-dimensaional matrix. At its core, it **captures high-dimensional data** and **annotates axis dimension names and iterators**, like a `table` has `RowNames` and `VariableNames`. A grid has three properties:

- `Data` captures the n-dimensional data matrix
- `Iter` captures each dimension iterator values
- `Dims` captures the names of each dimension
- `User` captures any user-defined data

The key benefit of using the grid class lies in the vast amount of transformations it provides, most of which can be chained:

```matlab
envelope1 = makegrid(true, {0:1000:10000, 0:50:200}, {'alt_ft', 'v_kts'});
envelope2 = makegrid([true, false], {["up", "dn"]}, {'gear'});
envelope3 = makegrid(true, {
    'alt_ft', 0:1000:1000
    'v_kts',  0:50:200
})

envelope1.union(envelope2, @or, false)
    .filter(true) ...
    .map(@produceEvidence) ...
    .save("evidence.mat") ...
    .map(@testRequirement) ...
    .dense(tico.TestStatus.Missing) ...
    .collapse("gear") ...
    .save("results.mat");
```

The whole alphabetical list of grid operations is:

|   |   |   |   |   |
|---|---|---|---|---|
| [`(@fcn)`](#grid-slicing) | [`(i1, i2, ...)`](#grid-slicing) | [`(index)`](#grid-slicing) | [`(key = v1, ...)`](#grid-slicing) | [`(mask)`](#grid-slicing) |
| [`{@fcn}`](#grid-slicing) | [`{i1, i2, ...}`](#grid-slicing) | [`{index}`](#grid-slicing) | [`{key = v1, ...}`](#grid-slicing) | [`{mask}`](#grid-slicing) |
| [`applyTo`](#grid-utilities) | [`assign`](#grid-slicing) | [`at`](#grid-slicing) | [`collapse`](#grid-form-transformations) | [`contains`](#grid-analysis) |
| [`data`](#grid-utilities) | [`dense`](#sparse-and-dense-grids) | [`distributed`](#grid-parallelisation) | [`each`](#grid-utilities) | [`every`](#grid-analysis) |
| [`except`](#grid-content-transformations) | [`extend`](#grid-form-transformations) | [`filter`](#grid-form-transformations) | [`find`](#grid-utilities) | [`first`](#grid-utilities) |
| [`gather`](#grid-parallelisation) | [`intersect`](#grid-joins) | [`iscompatible`](#grid-analysis) | [`isempty`](#grid-utilities) | [`issparse`](#sparse-and-dense-grids) |
| [`iter`](#grid-utilities) | [`join`](#grid-joins) | [`last`](#grid-utilities) | [`loadgrid`](#grid-utilities) | [`makegrid`](#grid-utilities) |
| [`map`](#grid-content-transformations) | [`ndims`](#grid-analysis) | [`numel`](#grid-analysis) | [`only`](#grid-content-transformations) | [`partition`](#grid-parallelisation) |
| [`permute`](#grid-form-transformations) | [`pipe`](#grid-utilities) | [`pluck`](#grid-content-transformations) | [`reject`](#grid-form-transformations) | [`retain`](#grid-form-transformations) |
| [`save`](#grid-utilities) | [`savegrid`](#grid-utilities) | [`size`](#grid-analysis) | [`slice`](#grid-slicing) | [`sort`](#grid-form-transformations) |
| [`sparse`](#sparse-and-dense-grids) | [`squeeze`](#grid-form-transformations) | [`struct`](#grid-utilities) | [`user`](#grid-utilities) | [`union`](#grid-joins) |
| [`vec`](#grid-content-transformations) | [`where`](#grid-slicing) | | | |

The grid class is inspired by [Laravel Collections](https://laravel.com/docs/9.x/collections).

The following sections provide an overview. For detailed help, use `help containers.Grid/funcname`.


## Grid Slicing

Just like within a `table`, you can subreference a grid **by index** or **by label**. The return value depends on your use of the operator. To index by numerical indices, use:

```matlab
grid(2, 2:3, 1) % returns a sub-grid
grid{2, 2:3, 1} % returns a sub-matrix
```

You can also use the following functional syntax:

```matlab
grid.slice(2, 2:3, 1)      % returns a sub-grid
grid.slice(2, 2:3, 1).Data % returns a matrix
```

You can also index by key / value pair (the order does not matter):

```matlab
grid("alt_ft", 1000, "gear", "up", "v_kts", 50:50:100)
```

You can also select individual iterators, providing a struct array:

```matlab
iter = struct("alt_ft", 1000, "v_kts", 50, "gear", "up");
grid(iter)
```

You can select values via logical mask - the output might be a sparse grid:

```matlab
mask = grid.Data == 42;
grid(mask)
```

You can select values via function handle evaluation (must return true or false):

```matlab
grid(@(x) x == 42)
```

You can access a value and its iterator by linear index using `at`:

```matlab
data = grid.at(42)
[data, iter] = grid.at(42)
```

All these subreferencing operations are applicable to assignments as well.
Use `()` to insert a sub-grid and `{}` to insert data.

```matlab
grid{2, 2:3, 1} = repmat(true, [1, 2, 1])
grid{"alt_ft", 1000, "gear", "up", "v_kts", 100} = false
grid{struct("alt_ft", 0, "v_kts", 50, "gear", "up")} = true
grid{grid.Data == 42} = 43
grid{@(x) x == 42} = 43
```

You can reduce the size of the grid by `filter()`ing certain values by function handle:

```matlab
grid.filter(@(x) x == 42)
grid.filter(@not) % to search for 0
```

The result of the `filter()` andoperation may or may not be sparse.
See [Sparse and Dense Grids] for more information.
The follow-up operations you can chain is not affected.
`reject()` is the logical opposite of `filter()`.
Both command achieve the same:

```matlab
grid.reject(nan)
grid.reject(@isnan)
```

You can filter the grid by object property or struct field (all options are equivalent):

```matlab
grid = makegrid(struct("Success", {true, false, true}), {1:3}, ["A"])
grid(".Success", true)
grid{".Success", true}
grid.slice(".Success", true)
grid.where(Success = true)
grid(@(v) v.Status == true)
```


## Grid Form Transformations

The following operations transform the dimensionality of grids: `collapse()`, `extend()`, `retain()`, `sort()`, and `permute()`.

You can reduce an $n$-dimensional grid to a $k$-dimensional grid using either `collapse()` (to specify $n-k$ dimensions to remove) or `retain()` (to specify all other $k$ dimensions). The first argument is the (list of) dimension(s) to collapse or retain, the second argument a reduction function that produces a scalar result from arrays or matrices of data:

```matlab
results.collapse("gear", @join)
envelope.collapse("v_kts", @or)
results.retain(["alt_ft", "v_kts"], @join)
```

Using `extend()` you can instead add new dimensions. Data from the previous sub-grid will be repeated along the axis, increasing the size of the hyperspace:

```matlab
envelope.extend("gear", ["up", "dn"])
```

The function `sort()` will reorder and permute iterators and dimension names to be alpanumerically increasing. Sorting grids does not modify the underlying data, and grids remain compatible for iterations.

```matlab
sorted = grid.sort()
assert(iscompatible(sorted, grid))
```

You can also manually `permute()` dimensions (though, not iterators):

```matlab
grid = grid.permute(["v_kts", "gear", "alt_ft"])
```


## Grid Content Transformations

The following operations transform the content of grids: `map()`, `except()`, `only()`, and `pluck()`.

You will use `map()` to apply M:N mapping functions to grid data or iterators and capture the result in another grid, or multiple output grids:

```matlab
grid = envelope.map(@produceEvidence)
grid = map(grid1, grid2, @evidenceWithTwoInputs)
[grid1, grid2] = envelope.map(@evidenceWithTwoOutputs)
[grid1, grid2] = map(grid3, grid4, @fcnWithTwoInputsAndOutputs)
```

`map()` will automatically run in parallel if the grid was `distributed()` before.

For any mapping, grid dimensions do not have to be identical. It is sufficient that both grids satisfy `iscompatible()`.

When working with structure or object grids (i.e. grids containing `struct` or objects as `Data`), you can use `except()`, `only()` and `pluck()` to work with fields and properties:

```matlab
grid.except("result") % will remove a field
grid.only(["A", "B"]) % will keep two fields only
grid.pluck("Status") % extracts property "Status" from object matrix
```

The commands above are conceptually identical to, but faster than:

```matlab
grid.map(@(s) rmfield(s, "result"))
grid.map(@(s) struct("A", s.A, "B", s.B))
grid.map(@(s) s.Status)
```


## Grid Utilities

This section contains a list of operations that might be useful utilities:

- `assign()` replaces the whole grid (useful for method chaining).
- `collect()` builds 1-dimensional grids from arrays.
- `data()` returns the data of a grid.
- `data(data)` writes data to the grid.
- `each()` is like `map()`, but the mapping function has no outputs.
- `find()` is like `filter()`, but returns the result data instead.
- `first(@fcn)` returns a single element, if found based on function `@fcn`.
- `isempty()` returns true if and only if the grid contains no data.
- `iter()` returns the iterator values of a grid as a struct array.
- `iter(dim = iter)` writes a specific iterator to the grid.
- `iter(iter)` writes iterator values to the grid.
- `last(@fcn)` returns a single element, if found based on function `@fcn`.
- `loadgrid()` is the logical opposite to `savegrid()`.
- `makegrid()` is a functional alias for the constructor `containers.Grid`.
- `pipe()` is for functional programming, to provide your own operation.
- `save()` is for saving to mat file (you can continue chaining operations after this).
- `savegrid()` is the functional counterpart to `save()`.
- `struct()` removes the class interface from the grid data, so you can serialize it to a MAT file more easily.
- `user()` returns the user data of a grid.
- `user(key = value)` writes user data to the grid, assuming `grid.User` is a struct.
- `user(user)` writes user data to the grid.

For more information, run `help containers.Grid/funcname`.


## Grid Analysis

The following operations provide insight into contents and structure of grids:

`iscompatible()` will return true if and only if multiple grids have the same dimension names and iterator values. The order of values and dimensions does not matter:

```matlab
tf = iscompatible(grid1, grid2)
```

`contains()` will return true if and only if the queried value is contained in the grid data, or the function handle returns true for **any** grid point:

```matlab
grid.contains(42)
grid.contains(@(answer) answer == 42)
```

`every()` is similar to `contains()`, but requires **all grid points** to contain the given value or fulfill the given function handle:

```matlab
grid.every(42)
grid.every(@(answer) answer == 42)
```

`size()` will return the number of iterator values in each dimension. This is slightly different from `size(grid.Data)`, since `size(grid)` does not truncate trailing ones:

```matlab
size(grid)      % might return [10, 5, 2, 1]
size(grid.Data) % might return [10, 5, 2]
```

`ndims()` returns the number of named dimensions -- again this is different from `ndims(grid.Data)`:

```matlab
ndims(grid)      % might return 4
ndims(grid.Data) % might return 3
```


## Grid Joins

Our grid joins are like a high-dimensional variation of relational database table joins. There are **inner** and **outer** joins. An **inner** join will result in the intersection of two rectangular hyperspaces. An **outer** join will result in the union space of two rectangular hyperspaces.

An example for an inner join:

```matlab
>> grid_1 = makegrid(rand(3,3,3), {1:3, 1:3, 1:3}, ["a", "b", "c"]);
>> grid_2 = makegrid(rand(3,3,3), {1:3, 2:4, 1:3}, ["b", "c", "d"]);
>> joined = intersect(grid_1, grid_2, @mean)
joined =
  2-dimensional Grid containing double with iterators:

    b: [1, 2, 3]
    c: [2, 3]

  6 iterations total
```

The same example for an outer join:

```matlab
>> joined = union(grid_1, grid_2, @mean, nan)
joined =
  4-dimensional Grid containing double with iterators:

    a: [1, 2, 3]
    b: [1, 2, 3]
    c: [1, 2, 3, 4]
    d: [1, 2, 3]

  36 iterations total
```

Either way, the first two arguments to `intersect()` and `union()` are the two grids to be joined. The third argument must be a pairwise function to produce a scalar value from each overlap. For outer joins, you also can specify missing values for the left and right grids, where they did not extend before.


## Sparse and Dense Grids

Some operations like `filter()` and `reject()` can destroy the regularity of a grid. The result will be a **sparse grid**, or in other words, a point cloud. A sparse grid has no dimension names in `.Dims` and only a single entry in `.Iter`, which is a struct array with any possible iterations.

Sparse grids may also consume less memory if the sparsity is very high (e.g. 99%).

You can check, whether a grid `issparse()` at any time.

To convert (dense) grids into sparse grids manually and vice versa, use the functions `sparse()` and `dense()`:

```matlab
>> envelope = tico('polarion', 'grid', 'PAR-108').filter()
envelope =
  22-dimensional sparse Grid containing logical with iterators:
    ...

  1307 iterations total

>> envelope.dense(false) % must specify neutral element
envelope =
  22-dimensional Grid containing logical with iterators:
    ...

  4704 iterations total (1307 containing <true>)
```

You can use [Grid Content Transformations] on sparse grids as usual.


## Grid Parallelisation

To parallelise work across nodes, you can distribute content of a grid to be processed on multiple workers. There are two aspects to this.

First option is to `partition()` a grid into a number of subspaces equal to the number of workers. After processing, reassemble the hyperspace using `union()`:

```matlab
grids = cell(1, 4)
[grids{:}] = grid.partition()
parfor k = 1:numel(grids)
    grids{k} = grids{k}.map(@workInParallel)
end
grid = union(grids{1}, grids(2:end))
```

Second option is to make a grid `distributed()`, which transports the contents to each worker equally, then perform the mapping in parallel, then `gather()` the distributed results back on the host:

```matlab
grid = grid.distributed().map(@workInParallel).gather()
```

You can also distribute a grid on construction, which is similar to matrices:

```matlab
grid = makegrid(data, iter, dims, 'distributed')
```

Using the partitioning approach, you have more fine control, which iterations are included with each subspace. However, this requires you to specify a mapping function that returns bin values 1-4 for each grid element. Read more in `help containers.Grid/partition`.



Maintainer
----------

This project is maintained by [Florian Schwaiger](fschwaiger@gmail.com).
