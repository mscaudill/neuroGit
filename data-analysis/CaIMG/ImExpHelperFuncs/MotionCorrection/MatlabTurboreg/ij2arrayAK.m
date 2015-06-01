function Array = ij2arrayAK(ImagePlus)


ijstack=ImagePlus.getImageStack();

slices=ijstack.getSize();
width=ijstack.getWidth();
height=ijstack.getHeight();

pixelarray = ijstack.getImageArray();
cellarray=cell(pixelarray);
Array=cell2mat(cellarray(1:slices));
Array=reshape(Array,width,height,slices);
Array=permute(Array,[2 1 3]);