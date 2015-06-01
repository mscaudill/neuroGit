target = 'E:\SatoSvobodaData\@Imaging\TA018\tiffproduct\TA018_1_Average_001.tif';
source = 'E:\SatoSvobodaData\@Imaging\TA018\tiffproduct\TA018_1_Average_001.tif';

Cropping = '0 0 126 126'; % left- top- right- and bottom-most pixels to consider
Transformation = '-translation'; % translation is currently the only suppported transformation
center=num2str(fix(size(source,1)/2)-1);
landmarks = [center,' ',center,' ',center,' ',center];
cmdstr=['-align -window s ',Cropping,' -window t ', Cropping,' ', Transformation, ' ', landmarks,' -hideOutput']

target=array2ijStackAK(target);
source=array2ijStackAK(source);

al=IJAlign_AK;
registered = al.doAlign(cmdstr, source, target);

registered = ij2arrayAK(registered);