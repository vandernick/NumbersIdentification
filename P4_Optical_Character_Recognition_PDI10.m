function P4_Optical_Character_Recognition_PDI10
%Matlab version:
%R2016b




%Nota: si es la primera vegada que s'executa el programa, primer demana a
%quina carpeta es troben les imatges d'entrenament. Despr?s demana la
%imatge en si en la que l'user ha d'escollir els numeros. Si es la segona
%vegada o mes, demana directament la imatge. Si es vol que torni a demanar
%la carpeta per entrenar, s'ha d'eliminar el fitxer 'trainingData.mat'.


%Looks if there already exists a file with the processed training data
entr_profile={};
train=false;
path='';
if(exist('trainingData.mat','file')==2) %existeix
    entr_profile=load('trainingData.mat');
    entr_profile=struct2cell(entr_profile);
    entr_profile=entr_profile{1,1};
else
    train=true;

    fmsg = msgbox('Choose directory of training objects','Message', 'modal');
    uiwait(fmsg); %blocks execution until uiresume is called or the figure h is deleted.
    path = uigetdir('Choose the folder with training numbers'); %demana directori
end  
    









%Read the input image
fmsg = msgbox('Choose image','Message', 'modal');
uiwait(fmsg); %blocks execution until uiresume is called or the figure h is deleted.
[img_filename, img_pathname] = uigetfile({'*.jpg';'*.jpeg';'*.png'},'Choose an image');
img = imread(strcat(img_pathname,img_filename));


%Image is processed to facilitate numbers recognition

resize=[400 250]; %files, columnes

img_gray=rgb2gray(img); %passa a gray
img_gray=imgaussfilt(img_gray); %filtre de suavitzat gausia per treure soroll

%top-hat to uniform illumination
img2=255-img_gray; %top-hat works if the background is black. Therefore, it makes negative
estr= strel('disk',20);
img_uni=imtophat(img2, estr);
img_uni=255-img_uni;


%otsu per binaritzar la img
img_bi=imbinarize(img_uni,'global'); %returns bw image with a threshold determined by otsu










%bounding box (algoritme de reconstruccio amb marcadors). Extracts numbers that user marks
tamany_img = size(img);
boolLine=false;
colLeft=tamany_img(2);
colRight=0;
filaBottom=0;
filaTop=0;
while(~boolLine)
    
    %linia que marca l'usuari
    imshow(img);
    linia= imline;
    pos=round(linia.getPosition());

    %es crea img buida de la mateixa mida que l'original, des del primer punt
    %de la line de l'usuari que es blanc (nums blancs, fons negre), sera el
    %punt blanc de la img buida. Se li fa dilatacions, fent AND amb l'original
    %fins que no canvii respecte l'iteracio anterior. Ja es te el num. Es mira
    %el pixel leftmost topmost de la imatge buida i ja es te l'extrem. 

    %crea funcio linia 
    if(pos(1,1)>=pos(2,1))
        x_incr=pos(1,1)-pos(2,1);%increment de x
        y_incr=pos(1,2)-pos(2,2);%increment de y
        n=pos(2,2);
        m=(y_incr/x_incr); %pendent (y augmenta cap avall)
        x_casella1=pos(2,1)-1;
    else
        x_incr=pos(2,1)-pos(1,1);%increment de x
        y_incr=pos(1,2)-pos(2,2);%increment de y
        n=pos(1,2);
        m=-(y_incr/x_incr); %pendent (y augmenta cap avall)
        x_casella1=pos(1,1)-1;
    end

    x1=1;
    y1=1;
    linia_f = zeros(1,x_incr);
    
    while(x1<=x_incr)
        linia_f(x1)=round(m*x1+n);%y=mx+n
        x1=x1+1;
    end


    %reconstruccio amb marcadors
    
    img_rec=logical(zeros(tamany_img(1),tamany_img(2)));%empty image
    img_biN=imcomplement(img_bi);
    %busca primer pixel negre, resseguint la linia marcada d'esquerra a dreta
    i=1;
    flag=0;
    
    while (i<=x_incr && flag==0)
        if(img_bi(linia_f(i),i+x_casella1)==0) %fosi s'ha trobat un negre
            img_rec(linia_f(i),i+x_casella1)=1; %marquem punt blanc, corresponent al 1r numero
            flag=1;
        end
        
        i=i+1;
    end
    
    %busca segon pixel negre, resseguint la linia marcada de dreta a esq
    %img(files,columnes), img(y,x)
    i=x_incr;
    flag=0;
    
    while (i>=1 && flag==0)
        if(img_bi(linia_f(i),i+x_casella1)==0) %si s'ha trobat un negre
            img_rec(linia_f(i),i+x_casella1)=1; %marquem punt blanc, corresponent al ultim numero
            flag=1;
        end
        
        i=i-1;
    end

    %dilate per obtenir els numeros 1r i ultim sencers
    bool1=false;
    nhood = [0 1 0;1 1 1;0 1 0];
    estructura = strel('arbitrary', nhood);
    img_dilatada=imdilate(img_rec, estructura);
    
    while(~bool1)
        img_dilatada2=imdilate(img_dilatada,estructura);
        img_dilatada2=img_dilatada2.*img_biN; %la part que ha arribat a un borde queda del mateix color perque queda multiplicada per 0 (borde es sempre negre)

        if(isequal(img_dilatada2, img_dilatada)) %si la nova dilatada es igual a l'anterior, deixem de dilatar
                bool1=true;
                img_rec=img_dilatada2;
        end

        img_dilatada=img_dilatada2;
    end
    

    %troba els punts mes extrems de la img_rec
    fila=0;
    boolTop=false;
    boolRight=false;
    boolLeft=false;
    boolBottom=false;
    
    while (fila<tamany_img(1))
        fila=fila+1;
        col=0;
        while (col<tamany_img(2))
            col=col+1;
            %top
            if(img_rec(fila,col)==1 && ~boolTop)
                boolTop=true;
                filaTop=fila;            
            end
            %left
            if(img_rec(fila,col)==1 && col<colLeft)
                boolLeft=true;
                
                colLeft=col;
            end
            %right
            if(img_rec(fila,col)==1 && col>colRight)
                boolRight=true;
                
                colRight=col;
            end
            %bottom
            if(img_rec(fila,col)==1 && fila>filaBottom)
                boolBottom=true;
                filaBottom=fila;
                
            end
        end
    end

    %comprova
    if(~boolTop || ~boolBottom || ~boolRight || ~boolLeft)
        f = errordlg('Error: numbers not correctly selected :((','Error PDI', 'modal');
    
    else
        boolLine=true;
   end
    
end

%bounding box with margin
filaTop=filaTop-5;
filaBottom=filaBottom+15;
colRight=colRight+5;
colLeft=colLeft-5;
width=colRight-colLeft;
height=filaBottom-filaTop;
img_box=imcrop(img_biN,[colLeft filaTop width height]); %copia una regio de la img on hi ha els nums
%imshow(img_box);
















%object extraction with Projection
%projection de columnes: (suma pixels blancs de cada columna)
tamany_img=size(img_box);
array_columnes=zeros(1,tamany_img(2));
%total_columnes=0;
col=0;
%num pixels columnes
while(col < tamany_img(2))
      col=col+1;
      pCol=0;
      files=0;
      while(files < tamany_img(1))
                files=files+1;
                if(img_box(files,col)==1)
                    pCol=pCol+1;
                end
      end
      array_columnes(col)=pCol;
                    
end

 
%limits de cada objecte 
limits=[];
objecte=false;
for i=1:tamany_img(2)
    if(~objecte)
        if(array_columnes(i)>0) %hi ha un objecte
            limits=[limits i]; %limit esquerra
            objecte=true; %esta dins l'objecte
        end
    else
        if(array_columnes(i)==0)
            limits=[limits i]; %limit dreta
            objecte=false; %esta fora l'objecte
        end
    end
end


%isolates objects
array_objectes=cell(1,1); %guarda les img de cada objecte
llargadaLimits=size(limits);
k=1;
for a=1:(llargadaLimits(2)/2) %cada objecte
        height=tamany_img(2);
        width=limits(k+1) - limits(k);
        array_objectes{a,1}=imcrop(img_box,[limits(k) 0 width height]);
        k=k+2;

        %retalla parts sobrants de laterals i top bottom:
        %troba els punts mes extrems de cada objecte
        labelled=array_objectes{a,1};
        tamany_labelled=size(labelled);
        
    
        colLeft=tamany_labelled(2);
        colRight=0;
        filaBottom=0;
        filaTop=0;
        fila=0;
        boolTop=false;
        boolRight=false;
        boolLeft=false;
        boolBottom=false;
        while (fila<tamany_labelled(1))
            fila=fila+1;
            col=0;
            while (col<tamany_labelled(2))
                col=col+1;
                %top
                if(labelled(fila,col)==1 && ~boolTop)
                    boolTop=true;
                    filaTop=fila;

                end
                %left
                if(labelled(fila,col)==1 && col<colLeft)
                    boolLeft=true;

                    colLeft=col;
                end
                %right
                if(labelled(fila,col)==1 && col>colRight)
                    boolRight=true;

                    colRight=col;
                end
                %bottom
                if(labelled(fila,col)==1 && fila>filaBottom)
                    boolBottom=true;
                    filaBottom=fila;

                end
            end
        end

        %comprova
        if(~boolTop || ~boolBottom || ~boolRight || ~boolLeft)
            disp('error');
        end


        %bounding box  
        width=colRight-colLeft;
        height=filaBottom-filaTop;

        array_objectes{a,1}=imcrop(labelled,[colLeft filaTop width height]);
    
end

















if(train==true) %s'ha d'entrenar
    disp('a');
    %training with region geometric profile descriptor
    llista= dir(path); %fitxers dins el directori  
    tamany_llista=size(llista);
    entr_profile=cell(tamany_llista(1),3);%[num_img, pixels_profile]. Atencio: els ultims valors poden estar buits
    %per culpa dels fitxers basura
    a=0;
    %per cada numero/coma
    for i = 1:(tamany_llista(1))
        %se suma el num de pixels per cada fila i per cada columna i es
        %concatenen. 
        if(llista(i).bytes>0) %no es fitxer basura
            a=a+1;

            path_img=strcat(path,'/', llista(i).name);
            img_entr = imread(path_img);
            img_entr=im2bw(img_entr);
            img_entr=imcomplement(img_entr);
            
            %escalates so numbers have the same size as image
            %Primer es treuen els bordes laterals i top/bottom:

            %troba els punts mes extrems de la img_entr
            tamany_imgE = size(img_entr);
            colLeft=tamany_imgE(2);
            colRight=0;
            filaBottom=0;
            filaTop=0;
            fila=0;
            boolTop=false;
            boolRight=false;
            boolLeft=false;
            boolBottom=false;
            while (fila<tamany_imgE(1))
                fila=fila+1;
                col=0;
                while (col<tamany_imgE(2))
                    col=col+1;
                    %top
                    if(img_entr(fila,col)==1 && ~boolTop)
                        boolTop=true;
                        filaTop=fila;

                    end
                    %left
                    if(img_entr(fila,col)==1 && col<colLeft)
                        boolLeft=true;

                        colLeft=col;
                    end
                    %right
                    if(img_entr(fila,col)==1 && col>colRight)
                        boolRight=true;

                        colRight=col;
                    end
                    %bottom
                    if(img_entr(fila,col)==1 && fila>filaBottom)
                        boolBottom=true;
                        filaBottom=fila;

                    end
                end
            end

             %Retalla bordes sobrants
            width=colRight-colLeft;
            height=filaBottom-filaTop;
            img_entr=imcrop(img_entr,[colLeft filaTop width height]); %queda una imatge on el num l'ocupa casi tota

            %forcem que totes les imatges tinguin el mateix tamany per tenir la
            %mateixa llargada de array_filcol
            img_entr=imresize(img_entr, resize); 


            array_files=zeros(1,resize(1));%conte num de pixels blancs de cada fila
            %total_files=0;%pixels blancs totals de totes les files
            array_columnes=zeros(1,resize(2));
            %total_columnes=0;
            col=0;
            %suma el num de pixels de cada columna
            while(col < resize(2))
                col=col+1;
                pCol=0;
                files=0;
                while(files < resize(1))
                    files=files+1;
                    if(img_entr(files,col)==1)
                        pCol=pCol+1;
                    end
                end
                array_columnes(col)=pCol;

            end


            %suma el num de pixels de cada fila
            files=0;

            while(files < resize(1))
                files=files+1;
                pFiles=0;
                col=0;
                while(col < resize(2))
                    col=col+1;
                    if(img_entr(files,col)==1)
                        pFiles=pFiles+1;
                    end
                end
                array_files(files)=pFiles;

            end


            array_filcol=[array_files array_columnes]; %concatena

            %es normalitza per despres mirar la diferencia entre proporcions
            sumA=sum(array_filcol(:));
            array_filcol=array_filcol/sumA;

            %guarda dades
            entr_profile{a,1}=llista(i).name; 
            entr_profile{a,2}=array_filcol;
            entr_profile{a,3}=img_entr; %no usat

        end

    end 

    save('trainingData.mat','entr_profile'); %guarda variable en fitxer
end












%gets profile descriptor and identifies numbers marked by user

num_objectes=size(array_objectes); %imatges de cada un dels nums de l'user
num_objectes=num_objectes(1);
array_identificats=cell(num_objectes,1); %noms dels arxius que s'assemblen mes als nums
for i = 1:num_objectes
    img_obj=imresize(array_objectes{i,1}, resize); %escala a la mida de les img d'entrenament
    %profile
    
        array_files=zeros(1,resize(1));%conte num de pixels blancs de cada fila
        %total_files=0;%pixels blancs totals de totes les files
        array_columnes=zeros(1,resize(2));
        %total_columnes=0;
        col=0;
        %num pixels columnes
        while(col < resize(2))
            col=col+1;
            pCol=0;
            files=0;
            while(files < resize(1))
                files=files+1;
                if(img_obj(files,col)==1)
                    pCol=pCol+1;
                end
            end
            array_columnes(col)=pCol;
                    
        end
        
        %num pixels files
        files=0;
        
        while(files < resize(1))
            files=files+1;
            pFiles=0;
            col=0;
            while(col < resize(2))
                col=col+1;
                if(img_obj(files,col)==1)
                    pFiles=pFiles+1;
                end
            end
            array_files(files)=pFiles;
                    
        end
        array_filcol=[array_files array_columnes]; %concatena
        
        %normalitza
        sumA=sum(array_filcol(:));
        array_filcol=array_filcol/sumA;
        
        
        %identifies object with k-NN
        sumDifIdentificat=10000000;
        nomIdentificat=entr_profile{1,1}; %inicialitza
        sizeEntrProf=size(entr_profile);
        for a=1:sizeEntrProf(1) %recorre cada objecte d'entrenament
            
            if(~isempty(entr_profile{a,1})) %no es dada basura
                
                %mira diferencia quadratica
                diferencia=array_filcol-entr_profile{a,2}; %diferencia entre descriptors (array)
                diferencia=diferencia.*diferencia; %quadrat
                sumDif=sum(diferencia(:)); %suma tots els valors de l'array
                
                %mira objecte mes semblant
                if(a==1)
                    sumDifIdentificat=sumDif; %inicialitza
                end
                if(sumDif<sumDifIdentificat)
                    sumDifIdentificat=sumDif;
                    nomIdentificat=entr_profile{a,1};%per ex '5_2.jpg'
                    
                end
                       
            end
            
        end
        
        array_identificats{i,1}=nomIdentificat;
    
end





%construeix string dient numeros seleccionats
strFinal='';
for i=1:num_objectes
    num=array_identificats{i,1};
    if(num(1)=='1' && num(2)=='0') %si es una coma
        num(1)='.';
    end
    strFinal=strcat(strFinal,num(1));
end

    



%mostra
tamany_imgB=size(img_box);


figure;
subplot(2,2,1) %(num files, num columnes, posicio assignada)
imshow(img);
title('Original image');

subplot(2,2,2)
imshow(img_bi);
title('After binarization');

subplot(2,2,3)
imshow(img_uni);
title('After illumination compensation');

subplot(2,2,4)
imshow(img_box);
title('Cropped text');
text(20, tamany_imgB(1) + 10, strcat('OCR results: ',strFinal));   
 
end


