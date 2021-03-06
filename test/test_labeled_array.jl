module TestLabeledArray

using FactCheck
using DataCubes

facts("LabeledArray tests") do
  context("constructor tests") do
    col1 = nalift(rand(10, 50))
    col2 = nalift(reshape(1:500, 10, 50))
    col3 = nalift(reshape(map(i->string("sym_",i), 1:500), 10, 50))
    col4 = nalift(hcat(rand(10,30), fill(:testsym, 10, 20)))
    axis1c1 = DictArray(k1=nalift(collect(101:110)), k2=nalift(collect(201:210)))
    axis1c2 = nalift(map(i->string("a_",i), 1:50))
    d = DictArray(c1=col1, c2=col2, c3=col3, c4=col4)
    larr1 = LabeledArray(d, (axis1c1, axis1c2))
    larr2 = LabeledArray(d, axis1=axis1c1, axis2=axis1c2)
    @fact larr1 --> larr2
    @fact convert(LabeledArray, LabeledArray([LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))],axis1=darr(k=[:x,:y]))) --> @larr(a=[3,5],b=[NA,3],axis[darr(k=[:x,:y])])
    @fact convert(LabeledArray, LabeledArray(nalift([LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))]),axis1=darr(k=[:x,:y]))) --> @larr(a=[3,5],b=[NA,3],axis[darr(k=[:x,:y])])
    @fact convert(LabeledArray, LabeledArray(map(Nullable,[LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))]),axis1=darr(k=[:x,:y]))) --> @larr(a=[3,5],b=[NA,3],axis1[darr(k=[:x,:y])])
    @fact convert(LabeledArray, [LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))]) --> @larr(a=[3,5],b=[NA,3])
    @fact convert(LabeledArray, nalift([LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))])) --> @larr(a=[3,5],b=[NA,3])
    @fact @larr(a=[1,2,3],b=1,axis1[k=[:A,:B,:C]]) --> larr(a=[1,2,3],b=[1,1,1],axis1=darr(k=[:A,:B,:C]))
    @fact larr(@larr(a=[1,2,3],b=1,axis[k=[:A,:B,:C]]), c=[:x,:y,:z], :d=>[1,2,3], axis1=darr(k=["X", "Y", "Z"])) --> larr(axis1=darr(k=["X","Y","Z"]), a=[1,2,3],b=[1,1,1],d=[1,2,3],c=[:x,:y,:z])
    @fact @larr(@larr(a=[1 NA;3 4;NA NA],:b=>[1.0 1.5;:sym 'a';"X" "Y"],c=1,axis[:U,NA,:W],axis[r=['m','n']]), c=[NA NA;3 4;5 6], :d=>:X, axis1[k=["g","h","i"]]) --> @larr(a=[1 NA;3 4;NA NA],b=[1.0 1.5;:sym 'a';"X" "Y"],c=[NA NA;3 4;5 6],d=reshape(fill(:X,6),3,2),axis2[r=['m','n']],axis1[k=["g","h","i"]])
    @fact_throws larr(a=[1,2,3],axis1=[1 2 3])
    @fact_throws LabeledArray([1 2 3],([1,2,3],[4,5,6]))
    @fact_throws LabeledArray([1,2,3],([1,2,3],[4,5,6]))
  end
  context("array related method tests") do
    arr = LabeledArray(
      DictArray(:a=>nalift(reshape(1:20, 5, 4)),
                :b=>nalift(reshape(2.0*(1:20),5,4)),
                2=>nalift(fill(:sym, 5, 4)),
                :third=>nalift(reshape(map(i->string("str_",i), 1:20), 5, 4))),
          axis1=DictArray(k1=nalift(["a","a","b","b","b"]), k2=nalift(collect(101:105))),
          axis2=DictArray(r1=nalift([:alpha,:beta,:gamma,:delta])))
    @fact arr[3,2] --> LDict(:a=>Nullable(8), :b=>Nullable(16.0), 2=>Nullable(:sym), :third=>Nullable("str_8"))
    @fact dcube.getindexpair(arr,3,2).second.second --> LDict(:a=>Nullable(8), :b=>Nullable(16.0), 2=>Nullable(:sym), :third=>Nullable("str_8"))
    @fact arr[1:3,2] --> LabeledArray(
                            DictArray(:a=>nalift([6,7,8]),
                                      :b=>nalift([12.0,14.0,16.0]),
                                      2=>nalift([:sym,:sym,:sym]),
                                      :third=>nalift(["str_6","str_7","str_8"])),
                            axis1=DictArray(k1=nalift(["a","a","b"]), k2=nalift(collect(101:103))))
    @fact arr[2:2,2:4] --> LabeledArray(
                            DictArray(:a=>nalift([7 12 17]),
                                      :b=>nalift([14.0 24.0 34.0]),
                                      2=>nalift([:sym :sym :sym]),
                                      :third=>nalift(["str_7" "str_12" "str_17"])),
                            axis=DictArray(k1=nalift(["a"]), k2=nalift([102])),
                            axis2=DictArray(r1=nalift([:beta,:gamma,:delta])))
    @fact collapse_axes(peel(larr(a=reshape(1:15,3,5),axis1=[10,11,12])[1,:])) --> collapse_axes(peel(larr(a=[1 4 7 10 13], axis1=[10])))
    @fact larr(a=reshape(1:15,3,5),axis1=[10,11,12])[:,1] --> larr(a=[1,2,3], axis1=[10,11,12])
    @fact collapse_axes(peel(larr(a=reshape(1:15,3,5),axis1=[10,11,12],axis2=[:,:y,:z,:u,:v])[1,:])) --> collapse_axes(peel(larr(a=[1 4 7 10 13], axis1=[10],axis2=[:,:y,:z,:u,:v])))
    @fact larr(a=reshape(1:15,3,5),axis1=[10,11,12],axis2=[:x,:y,:z,:u,:v])[:,1] --> larr(a=[1,2,3], axis1=[10,11,12])
    @fact size(arr) --> (5,4)
    #@fact eltype(arr) --> LDict{Any}
    @fact pick(arr,:a)[1,1].value --> 1
    @fact_throws pick(arr,:nonexistcol)
    @fact pick(larr(a=[1 2 3;4 5 6],axis1=darr(k=[:X,:Y])),:k) --> pick(larr(a=rand(2,3),axis1=darr(k=[:X,:Y])),:k)
    @fact pickaxis(larr(a=[1 2 3;4 5 6],axis=darr(k=[:X,:Y])),1) --> darr(k=[:X,:Y])
    @fact pickaxis(larr(a=[1 2 3;4 5 6],axis=darr(k=[:X,:Y])),1,:k) --> nalift([:X,:Y])
    @fact pick(arr,:b)[1,1].value --> 2.0
    @fact pick(arr,(:a,))[1][1,1].value --> 1
    @fact pick(arr,(:b,))[1][1,1].value --> 2.0
    @fact endof(arr) --> length(arr)
    @fact permutedims(arr, [2,1]) --> LabeledArray(DictArray(mapvalues(x->permutedims(x,[2,1]), arr.data.data)),
                                           axis1=arr.axes[2],
                                           axis2=arr.axes[1])
    #@fact permutedims(arr, [2,1]) --> transpose(arr)
    @fact_throws permutedims(arr, [2,1,3])
    @fact LabeledArray(DictArray(a=nalift([1 2 3])), axes2=nalift([100,101,102])) ==
          LabeledArray(DictArray(a=nalift([1 2 3])), axes2=nalift([100,101,102])) --> true
    @fact copy(arr) !== arr --> true
    @fact size(cat(1, arr, arr)) --> ntuple(n->n==1 ? size(arr,1)*2 : size(arr,n), ndims(arr))
    @fact size(cat(2, arr, arr)) --> ntuple(n->n==2 ? size(arr,2)*2 : size(arr,n), ndims(arr))
    @fact cat(2, arr) === arr --> true
    @fact_throws cat(larr([1 2 3;4 5 6]), larr([10 11;12 13;14 15]))
    @fact size(vcat(arr, arr)) --> ntuple(n->n==1 ? size(arr,1)*2 : size(arr,n), ndims(arr))
    @fact size(hcat(arr, arr)) --> ntuple(n->n==2 ? size(arr,2)*2 : size(arr,n), ndims(arr))
    @fact size(repeat(arr, inner=[5,2], outer=[3,4])) --> (size(arr,1)*5*3, size(arr,2)*2*4)
    @fact @larr(a=[1 2 3;4 5 6], 'x'=[:a :b :c;:x :y :z])[:a] --> nalift([1 2 3;4 5 6])
    @fact @larr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])[:a,:b] --> Any[nalift([1 2 3;4 5 6]), nalift([:a :b :c;:x :y :z])]
    @fact @larr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])[[:a,:b]] --> @darr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])
    @fact @larr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])[(:a,:b)] --> (nalift([1 2 3;4 5 6]), nalift([:a :b :c;:x :y :z]))
    @fact @larr(@larr(a=[1 2 3;4 5 6],axis1[k=[:x,:y]],axis2[r=['a','b','c']]), axis1[[1,NA]],axis2[[3,NA,1]]) --> @larr(a=[1 2 3;4 5 6],axis1[1,NA],axis2[3,NA,1])
    @fact @larr(@larr(a=[1 2 3;4 5 6],axis1[k=[:x,:y]],axis2[r=['a','b','c']]), axis2[[3,NA,1]]) --> @larr(a=[1 2 3;4 5 6],axis1[k=[:x,:y]],axis2[[3,NA,1]])
    @fact @larr([1 2 3;4 5 6]) --> LabeledArray(nalift([1 2 3;4 5 6]))
    @fact convert(LabeledArray, @larr([1 2 3;4 5 6])) --> larr([1 2 3;4 5 6])
  end
  context("additional method tests") do
    d1 = larr(:a=>nalift(reshape(1:20, 5, 4)),
              2=>nalift(fill(:sym, 5, 4)),
              :third=>nalift(reshape(map(i->string("str_",i), 1:20), 5, 4)))
    d2 = larr(:x=>nalift(reshape(1:20, 5, 4)),
              :third=>nalift(fill(:sym, 5, 4)),
              :z=>nalift(reshape(map(i->string("str_",i), 1:20), 5, 4)))
    @fact pick(merge(d1, d2), [:a,2]) --> pick(d1, [:a,2])
    @fact pick(merge(d1, d2), [:x,:third,:z]) --> pick(d2, [:x,:third,:z])
    @fact keys(peel(merge(d1, d2))) --> Any[:a,2,:third,:x,:z]
    @fact peel(delete(merge(d1, d2), :a,2,:third)) --> pick(d2, [:x, :z])
    @fact merge(larr(a=[1 2 3;4 5 6]), b=3.0) --> larr(a=[1 2 3;4 5 6], b=fill(3.0,2,3))
    @fact merge(larr(a=[1 2 3;4 5 6]), darr(x=[:a :b :c;:d :e :f])) --> larr(a=[1 2 3;4 5 6], x=[:a :b :c;:d :e :f])
    @fact merge(darr(a=[1 2 3;4 5 6]), larr(x=[:a :b :c;:d :e :f])) --> larr(a=[1 2 3;4 5 6], x=[:a :b :c;:d :e :f])
    @fact merge(larr(a=[1 2 3;4 5 6]), darr(x=[:a :b :c;:d :e :f]), b=3.0) --> larr(a=[1 2 3;4 5 6], x=[:a :b :c;:d :e :f], b=fill(3.0,2,3))
    @fact merge(darr(a=[1 2 3;4 5 6]), larr(x=[:a :b :c;:d :e :f]), b=3.0) --> larr(a=[1 2 3;4 5 6], x=[:a :b :c;:d :e :f], b=fill(3.0,2,3))
    @fact pick(d1, [:a]) --> DictArray(a=pick(d1, :a))
    @fact mapslices(x->LDict(:c=>Nullable(length(x))),@larr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"],axis1[k=[:x,:y]],axis2[r=[:m,:n,:p]]),[1]) --> @larr(c=[2,2,2], axis1[r=[:m,:n,:p]])
    @fact mapslices(x->LDict(:c=>Nullable(length(x))),@larr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"],axis1[k=[:x,:y]],axis2[r=[:m,:n,:p]]),1) --> @larr(c=[2,2,2], axis1[r=[:m,:n,:p]])
    @fact mapslices(x->LDict(:c=>Nullable(length(x))),@larr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"],axis1[k=[:x,:y]],axis2[r=[:m,:n,:p]]),[2]) --> @larr(c=[3,3], axis1[k=[:x,:y]])
    @fact mapslices(x->LDict(:c=>Nullable(length(x))),@larr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"],axis1[k=[:x,:y]],axis2[r=[:m,:n,:p]]),2) --> @larr(c=[3,3], axis1[k=[:x,:y]])
    @fact mapslices(x->Nullable(length(x)),@larr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"]),[1]) --> LabeledArray(@nalift([2,2,2]), axes1=@nalift([1,2,3]))
    @fact size(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> (2,3)
    @fact mapslices(x->LDict(:c1=>DataCubes.naop_plus(x[:a],x[:b]),:c2=>Nullable(10)), @larr(a=[1 2 3;4 5 6],b=[1.0 2.0 3.0;4.0 5.0 6.0]), []) --> @larr(c1=[2.0 4.0 6.0;8.0 10.0 12.0], c2=@rap reshape(_,(2,3)) fill (10,6)...)
    #@fact typeof(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> Array{Pair{Nullable{Int64},Pair{Nullable{Int64},DataCubes.LDict{Symbol,Nullable{Int64}}}},2}
    @fact typeof(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> DataCubes.LabeledArray{DataCubes.LDict{Symbol,Nullable{Int64}},2,Tuple{DataCubes.DefaultAxis,DataCubes.DefaultAxis},DataCubes.DictArray{Symbol,2,DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}},Nullable{Int64}}}
    @fact eltype(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> DataCubes.LDict{Symbol,Nullable{Int64}}
    #@fact eltype(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> Pair{Nullable{Int64},Pair{Nullable{Int64},DataCubes.LDict{Symbol,Nullable{Int64}}}}
    @fact mapslices(x -> x, @larr(a=[1 2 3;4 5 6]), []) --> @larr(a=[1 2 3;4 5 6])
    @fact mapslices(x -> darr(a=[x[:a].value+i for i in 0:3]), @larr(a=[1 2 3;4 5 6]), []) --> reshape(larr(a=[1,2,3,4,4,5,6,7,2,3,4,5,5,6,7,8,3,4,5,6,6,7,8,9]), 4, 2, 3)
    @fact mapslices(x -> larr(a=[x[:a].value+i for i in 0:3]), @larr(a=[1 2 3;4 5 6]), []) --> reshape(larr(a=[1,2,3,4,4,5,6,7,2,3,4,5,5,6,7,8,3,4,5,6,6,7,8,9]), 4, 2, 3)

    @fact mapslices(x->darr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis2=[:m,:n,:p,:o,:q],axis3=["X","Y"]), [1]) --> larr(l=reshape(repeat(collect(1:4),outer=[10]),4,5,2),p=reshape(repeat([:U,:V,:W,:O],outer=[10]),4,5,2),axis2=[:m,:n,:p,:o,:q],axis3=["X","Y"])
    @fact mapslices(x->darr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis2=[:m,:n,:p,:o,:q],axis3=["X","Y"]), [1]) --> larr(l=reshape(repeat(collect(1:4),outer=[10]),4,5,2),p=reshape(repeat([:U,:V,:W,:O],outer=[10]),4,5,2),axis2=[:m,:n,:p,:o,:q],axis3=["X","Y"])
    @fact mapslices(x->larr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis2=[:m,:n,:p,:o,:q],axis3=["X","Y"]), [1]) --> larr(l=reshape(repeat(collect(1:4),outer=[10]),4,5,2),p=reshape(repeat([:U,:V,:W,:O],outer=[10]),4,5,2),axis2=[:m,:n,:p,:o,:q],axis3=["X","Y"])
    @fact mapslices(x->larr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O], axis1=[:m,:n,:p,:q]), larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis3=["X","Y"]), [1]) --> larr(l=reshape(repeat(collect(1:4),outer=[10]),4,5,2),p=reshape(repeat([:U,:V,:W,:O],outer=[10]),4,5,2),axis1=[:m,:n,:p,:q],axis3=["X","Y"])
    @fact mapslices(x->[11,21,31,41], larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis3=["X","Y"]), [1]) --> larr(reshape(repeat([11,21,31,41],outer=[10]),4,5,2),axis3=["X","Y"])

    @fact mapslices(x->darr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis2=[:m,:n,:p,:o,:q],axis3=["X","Y"]), [2]) --> larr(l=reshape(repeat(collect(1:4),outer=[6]),4,3,2),p=reshape(repeat([:U,:V,:W,:O],outer=[6]),4,3,2),axis2=[:a,:b,:c],axis3=["X","Y"])
    @fact mapslices(x->darr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis2=[:m,:n,:p,:o,:q],axis3=["X","Y"]), [2]) --> larr(l=reshape(repeat(collect(1:4),outer=[6]),4,3,2),p=reshape(repeat([:U,:V,:W,:O],outer=[6]),4,3,2),axis2=[:a,:b,:c],axis3=["X","Y"])
    @fact mapslices(x->larr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis2=[:m,:n,:p,:o,:q],axis3=["X","Y"]), [2]) --> larr(l=reshape(repeat(collect(1:4),outer=[6]),4,3,2),p=reshape(repeat([:U,:V,:W,:O],outer=[6]),4,3,2),axis2=[:a,:b,:c],axis3=["X","Y"])
    @fact mapslices(x->larr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O], axis1=[:m,:n,:p,:q]), larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis3=["X","Y"]), [2]) --> larr(l=reshape(repeat(collect(1:4),outer=[6]),4,3,2),p=reshape(repeat([:U,:V,:W,:O],outer=[6]),4,3,2),axis1=[:m,:n,:p,:q],axis2=[:a,:b,:c],axis3=["X","Y"])
    @fact mapslices(x->[11,21,31,41], larr(a=rand(3,5,2),axis1=[:a,:b,:c],axis3=["X","Y"]), [2]) --> larr(reshape(repeat([11,21,31,41],outer=[6]),4,3,2),axis2=[:a,:b,:c],axis3=["X","Y"])

    @fact mapslices(x->x[:a][1,1].value==1 ? LDict(:a=>Nullable(1)) : LDict(:a=>nalift([1 2 3])), larr(a=[1 2 3;4 5 6]),[1]) --> nalift(DataCubes.simplify_array(Any[LDict(:a=>1), LDict(:a=>[1 2 3]), LDict(:a=>[1 2 3])]))
    @fact (i=0;mapslices(x->x[:a][1,1].value<=2 ? (i+=1;LDict(:a=>i)) : LDict(:b=>-1), larr(a=[1 2 3;4 5 6],axis1=[:X,:Y]),[1])) --> nalift(DataCubes.simplify_array(Any[LDict(:a=>1), LDict(:a=>2), LDict(:b=>-1)]))
    @fact (i=0;mapslices(x->x[:a][1,1].value<=2 ? (i+=1;LDict(:a=>i)) : LDict(:a=>-1), larr(a=[1 2 3;4 5 6],axis1=[:X,:Y]),[1])) --> larr(a=[1,2,-1])

    @fact mapslices(x->[1], larr(a=Int[]), [1])  --> isnull
    @fact size(mapslices(x->[1], larr(a=rand(0,5,3)), [2])) --> (0,3)
    @fact mapslices(x->msum(x,1,2), larr(reshape(1:24,2,3,4),axis=[:a,:b],axis=['x','y','z']),2,1) --> larr(reshape([1,3,6,10,15,21,7,15,24,34,45,57,13,27,42,58,75,93,19,39,60,82,105,129],2,3,4),axis=[:a,:b],axis=['x','y','z'])
    @fact mapslices(x->msum(x,2,1), 3.0*larr(reshape(1:24,2,3,4),axis=[:a,:b],axis=['x','y','z']),[2,1]) --> 3.0*larr(reshape([1,3,6,10,15,21,7,15,24,34,45,57,13,27,42,58,75,93,19,39,60,82,105,129],2,3,4),axis=[:a,:b],axis=['x','y','z'])

    @fact map(x->LDict(:c=>x[:a]), @larr(a=[1,2,3],b=[4,5,6],axis[[:x,:y,:z]])) --> @larr(c=[1,2,3],axis1[[:x,:y,:z]])
    @fact map(x->x[:a], @larr(a=[1,2,3],b=[4,5,6],axis[[:x,:y,:z]])) --> @larr([1,2,3],axis1[[:x,:y,:z]])
    @fact dcube.create_dict(@larr(a=[1 NA NA;4 5 6],b=[NA NA 6; 7 8 9],axis2[r=[:x,:y,:z]]))[Nullable(2)][LDict(:r=>Nullable(:z))][:a].value --> 6
    @fact Set(keys(dcube.create_dict(@larr(a=[1 NA NA;4 5 6],b=[NA NA 6; 7 8 9],axis2[r=[:x,:y,:z]]))[Nullable(1)])) --> Set([LDict(:r=>Nullable(:x)), LDict(:r=>Nullable(:z))])
    @fact dcube.create_dict(@larr(a=[1 NA NA;4 5 6],b=[NA NA 6; 7 8 9],axis2[r=[:x,:y,:z]]))[Nullable(1)][LDict(:r=>Nullable(:x))] --> LDict(:a=>Nullable(1), :b=>Nullable{Int}())
    @fact reverse(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]])) --> @larr(a=[4 5 6;1 2 3],axis2[r=[:x,:y,:z]])
    @fact_throws reverse(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]), 1)
    @fact reverse(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[1]) --> @larr(a=[4 5 6;1 2 3],axis2[r=[:x,:y,:z]])
    @fact reverse(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2]) --> @larr(a=[3 2 1;6 5 4],axis2[r=[:z,:y,:x]])
    @fact reverse(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1:2) --> @larr(a=[6 5 4;3 2 1],axis2[r=[:z,:y,:x]])
    @fact flipdim(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),2) --> @larr(a=[3 2 1;6 5 4],axis2[r=[:z,:y,:x]])
    @fact flipdim(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1,2) --> @larr(a=[6 5 4;3 2 1],axis2[r=[:z,:y,:x]])
    @fact reshape(larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],axis1=darr(k1=[:a,:b],k2=[100,101]),axis2=[:m,:n,:p]),6) --> larr(a=[1,4,2,5,3,6],b=[10,13,11,14,12,15], axis1=darr(k1=repmat([:a,:b],3),k2=repmat([100,101],3),x1=[:m,:m,:n,:n,:p,:p]))
    @fact_throws reshape(larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],axis1=darr(k1=[:a,:b],k2=[100,101]),axis2=[:m,:n,:p]),2,1,5)
    @fact reshape(larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],axis1=darr(k1=[:a,:b],k2=[100,101]),axis2=[:m,:n,:p]),(6,)) --> larr(a=[1,4,2,5,3,6],b=[10,13,11,14,12,15], axis1=darr(k1=repmat([:a,:b],3),k2=repmat([100,101],3),x1=[:m,:m,:n,:n,:p,:p]))
    @fact reshape(larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],axis1=darr(k1=[:a,:b],k2=[100,101]),axis2=[:m,:n,:p]),1,6) --> @rap permutedims(_,[2,1]) reshape(_,6,1) larr(a=[1,4,2,5,3,6],b=[10,13,11,14,12,15], axis1=darr(k1=repmat([:a,:b],3),k2=repmat([100,101],3),x1=[:m,:m,:n,:n,:p,:p]))
    @fact_throws reshape(larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],axis1=darr(k1=[:a,:b],k2=[100,101]),axis2=[:m,:n,:p]),1,3)
    @fact reshape(larr([1 2 3;4 5 6],axis1=[10,11]),1,6) --> larr([1 4 2 5 3 6], axis2=repmat([10,11],3))
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4)),[1],0) --> larr([3 15 27 39;7 19 31 43;11 23 35 47])
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4)),[1,2],0) --> larr([21,57,93,129])
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4)),[1,2,3],0).value --> 300
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4),axis1=darr(k1=[:a,:b]),axis3=[:x,:y,:z,:w]),[1],0) --> larr([3 15 27 39;7 19 31 43;11 23 35 47],axis2=[:x,:y,:z,:w])
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4),axis1=darr(k1=[:a,:b]),axis3=[:x,:y,:z,:w]),[1,2],0) --> larr([21,57,93,129],axis1=[:x,:y,:z,:w])
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4),axis1=darr(k1=[:a,:b]),axis3=[:x,:y,:z,:w]),[1,2,3],0).value --> 300
    # runnability test when the result is empty.
    @fact size(@rap permutedims(_,[2,1]) @select((@rap permutedims(_,[2,1]) larr(r=rand(8,20), axis1=darr(a=rand(8),b=101:108))), :r=_r.*100, where[_r.>1])) --> (0,0)
    @fact reorder(larr('x'=>1:10, 3=>11:20, axis1=101:110), 3) --> larr(3=>11:20, 'x'=>1:10, axis1=101:110)
    @fact reorder(larr(c1=1:10,c2=11:20),:c2,:c1) --> reorder(larr(c1=1:10,c2=11:20),:c2)
    @fact reorder(larr(c1=1:10,c2=11:20),:c2,:c1) --> larr(c2=11:20,c1=1:10)
    @fact rename(larr('x'=>1:10, 3=>11:20, axis1=101:110), 1) --> larr(1=>1:10, 3=>11:20, axis1=101:110)
    @fact rename(larr(c1=1:10,c2=11:20),:a,:b) --> larr(a=1:10,b=11:20)
    @fact cat(1, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis1=[:u,:v]), larr(b=['x' 'y' 'z'], d=[:m :n :p], axis1=[3])) --> larr(reshape(@larr(a=[1,4,NA,2,5,NA,3,6,NA],b=['a','d','x','b','e','y','c','f','z'],d=[NA,NA,:m,NA,NA,:n,NA,NA,:p]), 3, 3), axis1=[:u,:v,3])
    @fact cat(1, larr(a=1.0*[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis1=[:u,:v]), larr(b=['x' 'y' 'z'], d=[:m :n :p], axis1=[3])) --> larr(reshape(@larr(a=[1.0,4.0,NA,2.0,5.0,NA,3.0,6.0,NA],b=['a','d','x','b','e','y','c','f','z'],d=[NA,NA,:m,NA,NA,:n,NA,NA,:p]), 3, 3), axis1=[:u,:v,3])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis1=[:u,:v]), larr(b=['x','y'], d=[:m,:n], axis1=[:u,:v])) --> larr(reshape(@larr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f','x','y'], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis1=[:u,:v])
    @fact cat(2, larr(a=1.0*[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis1=[:u,:v]), larr(b=['x','y'], d=[:m,:n], axis1=[:u,:v])) --> larr(reshape(@larr(a=[1.0,4.0,2.0,5.0,3.0,6.0,NA,NA], b=['a','d','b','e','c','f','x','y'], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis1=[:u,:v])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), larr(b=[10,11], d=[:m,:n])) --> reshape(@larr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4)
    @fact cat(2, larr(a=1.0*[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), larr(b=[10,11], d=[:m,:n])) --> reshape(@larr(a=[1.0,4.0,2.0,5.0,3.0,6.0,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4)
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis2=darr(r=[:x,:y,:z])), larr(b=[10,11], d=[:m,:n])) --> larr(reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis2=@darr(r=[:x,:y,:z,NA]))
    @fact cat(2, larr(a=1.0*[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis2=darr(r=[:x,:y,:z])), larr(b=[10,11], d=[:m,:n])) --> larr(reshape(@darr(a=[1.0,4.0,2.0,5.0,3.0,6.0,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis2=@darr(r=[:x,:y,:z,NA]))
    # this will cause a NullException().
    #@fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'],axis1=[100,200]), larr(b=[10 11]', d=[:m :n]',axis1=[100,200],axis2=darr(r=[:k]))) --> larr(reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis1=[100,200],axis2=[1,2,3,LDict(:r=>Nullable(:k))])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'],axis1=[100,200]), larr(b=permutedims([10 11], (2,1)), d=permutedims([:m :n], (2,1)),axis1=[100,200],axis2=[:k])) --> larr(reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis1=[100,200],axis2=[1,2,3,:k])
    @fact cat(2, larr(a=1.0*[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'],axis1=[100,200]), larr(b=permutedims([10 11], (2,1)), d=permutedims([:m :n], (2,1)),axis1=[100,200],axis2=[:k])) --> larr(reshape(@darr(a=[1.0,4.0,2.0,5.0,3.0,6.0,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis1=[100,200],axis2=[1,2,3,:k])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis2=[:x,:y,:z]), larr(b=[10,11], d=[:m,:n])) --> larr(reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis2=[Nullable(:x),Nullable(:y),Nullable(:z),Nullable{Symbol}()])
    @fact cat(2, larr(a=1.0*[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis2=[:x,:y,:z]), larr(b=[10,11], d=[:m,:n])) --> larr(reshape(@darr(a=[1.0,4.0,2.0,5.0,3.0,6.0,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis2=[Nullable(:x),Nullable(:y),Nullable(:z),Nullable{Symbol}()])
    @fact merge(larr(a=[1,2,3],b=[:x,:y,:z],axis1=[:a,:b,:c]),darr(c=[4,5,6],b=[:m,:n,:p]),darr(a=["X","Y","Z"])) --> larr(a=["X","Y","Z"],b=[:m,:n,:p],c=[4,5,6],axis1=[:a,:b,:c])
    @fact @larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]])[2:-1:1,2] --> larr(a=[5,2])
    @fact @larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]])[[2,1],2] --> larr(a=[5,2])
    @fact @larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]])[[2,1],2:3] --> larr(a=[5 6;2 3],axis2=darr(r=[:y,:z]))
    #@fact sub(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2) --> getindex(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2)
    #@fact sub(@larr(a=1.0*[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2) --> getindex(@larr(a=1.0*[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2)
    #@fact sub(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2:3) --> getindex(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2:3)
    #@fact sub(@larr(a=1.0*[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2:3) --> getindex(@larr(a=1.0*[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2:3)
    @fact view(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2) --> larr(a=[5,2])
    @fact view(@larr(a=1.0*[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2) --> larr(a=1.0*[5,2])
    @fact view(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1, 2:3) --> larr(a=[2,3], axis1=darr(r=[:y,:z]))
    @fact view(@larr(a=1.0*[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1, 2:3) --> larr(a=1.0*[2,3], axis1=darr(r=[:y,:z]))
    #@fact sub(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1, 2:3) --> larr(a=[2 3], axis2=darr(r=[:y,:z]))
    #@fact sub(@larr(a=1.0*[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1, 2:3) --> larr(a=1.0*[2 3], axis2=darr(r=[:y,:z]))
    @fact_throws larr(a=[1,2,3], axis1=[4,5,6], axis2=[:a,:b,:c])
    @fact_throws larr(a=[1,2,3], axis1=[4,5])
    @fact_throws larr(axis1=[4,5])
    @fact_throws LabeledArray(a=[1,2,3], ([4,5,6],[7,8,9]))
    @fact_throws larr(a=rand(4,5), axis1=rand(4,2))
    @fact size(similar(larr(rand(3,5)))) --> (3,5)
    @fact typeof(similar(larr(rand(3,5)))) --> LabeledArray{Nullable{Float64},2,Tuple{DataCubes.DefaultAxis,DataCubes.DefaultAxis},DataCubes.AbstractArrayWrapper{Nullable{Float64},2,DataCubes.FloatNAArray{Float64,2,Array{Float64,2}}}}

    @fact size(similar(larr(rand(3,5),axis2=[:a,:b,:c,:d,:e]))) --> (3,5)
    @fact typeof(similar(larr(rand(3,5),axis2=[:a,:b,:c,:d,:e]))) --> LabeledArray{Nullable{Float64},2,Tuple{DataCubes.DefaultAxis,DataCubes.AbstractArrayWrapper{Nullable{Symbol},1,Array{Nullable{Symbol},1}}},DataCubes.AbstractArrayWrapper{Nullable{Float64},2,DataCubes.FloatNAArray{Float64,2,Array{Float64,2}}}}
    @fact size(similar(larr(k=rand(3,5),axis=[:a,:b,:c]))) --> (3,5)
    @fact typeof(similar(larr(k=rand(3,5),axis=[:a,:b,:c]))) --> LabeledArray{DataCubes.LDict{Symbol,Nullable{Float64}},2,Tuple{DataCubes.AbstractArrayWrapper{Nullable{Symbol},1,Array{Nullable{Symbol},1}},DataCubes.DefaultAxis},DataCubes.DictArray{Symbol,2,DataCubes.AbstractArrayWrapper{Nullable{Float64},2,DataCubes.FloatNAArray{Float64,2,Array{Float64,2}}},Nullable{Float64}}}
    #@fact typeof(similar(larr(a=rand(3,5), axis1=darr(k=[1,2,3])))) --> LabeledArray{DataCubes.LDict{Symbol,Nullable{Float64}},2,Tuple{DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}},Nullable{Int64}},Array{Nullable{Int64},1}},DataCubes.DictArray{Symbol,2,DataCubes.AbstractArrayWrapper{Nullable{Float64},2,DataCubes.FloatNAArray{Float64,2,Array{Float64,2}}},Nullable{Float64}}}
    #@fact typeof(similar(larr(rand(3,5), axis1=darr(k=[1,2,3])))) --> LabeledArray{Nullable{Float64},2,Tuple{DataCubes.DictArray{Symbol,1,DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}},Nullable{Int64}},Array{Nullable{Int64},1}},DataCubes.AbstractArrayWrapper{Nullable{Float64},2,DataCubes.FloatNAArray{Float64,2,Array{Float64,2}}}}
    #@fact typeof(similar(larr(rand(3,5), axis1=[1,2,3]))) --> LabeledArray{Nullable{Float64},2,Tuple{DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}},Array{Nullable{Int64},1}},DataCubes.AbstractArrayWrapper{Nullable{Float64},2,DataCubes.FloatNAArray{Float64,2,Array{Float64,2}}}}
    @fact sortperm(larr(a=[1,7,4,3,5,3],axis1=enumeration([1,12,13,14,15,16])),1,:a) --> ([1,4,6,3,5,2],)
    @fact sortperm(larr(a=enumeration([1,7,4,3,5,3]),axis1=enumeration([1,12,13,14,15,16])),1,:a) --> ([1,2,3,4,6,5],)

    context("show tests") do
      @fact show(larr(view([1,2],1))) --> nothing
      @fact show(larr(a=[])) --> nothing
      @fact show(larr(a=rand(2))) --> nothing
      @fact show(larr(a=rand(2), axis=[:X,:Y])) --> nothing
      @fact show(larr(a=rand(2,3), axis1=[:a,:b], axis2=["X","Y","Z"])) --> nothing
      @fact show(larr(a=rand(2,3), axis2=["X","Y","Z"])) --> nothing
      @fact show(larr(a=rand(2,3), axis2=darr(k=["X","Y","Z"]))) --> nothing
      @fact show(larr(a=rand(2,3), axis=["X","Y"])) --> nothing
      @fact show(larr(a=rand(2,3))) --> nothing
      @fact show(larr(a=rand(2,3,2), axis3=[:x,:y])) --> nothing
      @fact show(larr(a=rand(2,3,2,2))) --> nothing
      @fact show(larr(a=rand(2,3,2,2))) --> nothing
      @fact (dcube.set_showsize!(5,5);show(larr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_showheight!(3);show(larr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_showwidth!(3);show(larr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_default_showsize!();nothing) --> nothing
      @fact (dcube.set_showalongrow!(false);show(larr(a=rand(3),b=rand(3),c=fill(:X,3)))) --> nothing
      @fact (dcube.set_showalongrow!(false);show(larr(a=rand(3),b=rand(3),c=fill(:X,3), axis=['X','Y','Z']))) --> nothing
      @fact (dcube.set_showalongrow!(false);show(larr(a=rand(3),b=rand(3),c=fill(:X,3), axis=darr(k=['X','Y','Z'])))) --> nothing
      @fact (dcube.set_showalongrow!(true);show(larr(a=rand(3),b=rand(3),c=fill(:X,3)))) --> nothing
      @fact (dcube.set_showalongrow!(false);show(larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
      @fact (dcube.set_showalongrow!(false);show(larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5),axis1=darr(k=['X','Y','Z'])))) --> nothing
      @fact (dcube.set_showalongrow!(true);show(larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5),axis1=darr(k=['X','Y','Z'])))) --> nothing
      @fact (dcube.set_showalongrow!(false);show(larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5),axis2=darr(k=['X','Y','Z','U','V'])))) --> nothing
      @fact (dcube.set_showalongrow!(true);show(larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5),axis2=darr(k=['X','Y','Z','U','V'])))) --> nothing
      @fact (dcube.set_showalongrow!(true);show(larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
      @fact (dcube.set_format_string!(Float64, "%0.2f");show(larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
      @fact (dcube.set_format_string!(Float64, "%0.8g");show(larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing

      @fact (dcube.set_dispsize!(5,5);show(STDOUT,MIME("text/html"),larr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_dispheight!(3);show(STDOUT,MIME("text/html"),larr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_dispwidth!(3);show(STDOUT,MIME("text/html"),larr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_dispwidth!(3);show(STDOUT,MIME("text/html"),larr(a=rand(2,3,4)))) --> nothing
      @fact (dcube.set_dispwidth!(3);show(STDOUT,MIME("text/html"),larr(a=view([1,2],1)))) --> nothing
      @fact (dcube.set_default_dispsize!();nothing) --> nothing
      @fact (dcube.set_dispalongrow!(false);show(STDOUT,MIME("text/html"),larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
      @fact (dcube.set_dispalongrow!(true);show(STDOUT,MIME("text/html"),larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
      @fact (dcube.set_format_string!(Float64, "%0.2f");show(STDOUT,MIME("text/html"),larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
      @fact (dcube.set_format_string!(Float64, "%0.8g");show(STDOUT,MIME("text/html"),larr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
    end
  end
end

end
