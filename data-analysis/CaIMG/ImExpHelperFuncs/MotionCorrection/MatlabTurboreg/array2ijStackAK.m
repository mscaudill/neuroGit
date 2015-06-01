function out = array2ijStackAK(in)

in = single(in);
si = size(in);
ijStack = ij.ImageStack(si(2),si(1));
if length(si)==2
    Pix = reshape(in',(si(2)*si(1)),1);
    ip = ij.process.FloatProcessor(si(2), si(1),Pix);
    ijStack.addSlice('frame', ip);
    clear ip
else
    for i=1:si(3)
        Pix = reshape((in(:,:,i)'),(si(2)*si(1)),1);
        ip = ij.process.FloatProcessor(si(2), si(1),Pix);
        ijStack.addSlice('frame', ip);
        clear ip
    end
end
out = ij.ImagePlus('test',ijStack);