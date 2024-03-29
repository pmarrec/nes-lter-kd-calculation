%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculation of light attenuation coefficient Kd from CTD profiles
% Light attenuation coefficient are calculated from the linear regression
% between depth and the corresponding log value of PAR during daytime casts
% (PAR >10 umol photons m-2 s-1), when the observed R2 was higher than 0.70
% R2 values < 0.7 resulted of a substantial ship shading.
% Mean beam attenuation (At) in the upper 10m was calculated for each cast
% Using daytime cast information,  a relationship (linear regression) was
% established between mean beam attenuation and Kd for each cast.
% During nighttime casts, Kd was estiamted from the average beam attenuation
% in the upper 10 m using the slope and intercept from equation
% Kd_mdl = m * At + b
% For Ar39b, no significant linear relationship between Kd and Beam
% Attenuation was retrieved because of technical problem with the
% transmitter. No Kd_mdl value was calculated for this cruise.
% The final Kd to use as light attenuation coefficient is indicated in the
% last column of the output file. It corresponds to the Kd value obtained
% during daytime casts (if R2 log(PAR) vs. Depth >0.70) or to the Kd values
% obatined from nighttime cast from the Beam Attenuation (or if daytime R2
% log(PAR) vs. Depth <0.70).
% 
% Input files: REST-API CTD csv files or cnv files for en655 from R2R 
% (https://www.rvdata.us/search/cruise/EN655, 
% except compromised casts 12 and 15) read using the readCnv function 
% from US191/ctdPostProcessing (https://github.com/US191/ctdPostProcessing.git) 
% and REST-API CTD metadata providing a list of casts for a given cruise. 
% Input variable: PrDM = CTD Depth; Par = CTD PAR; CStarAt0 = CTD Beam Attenuation.
% 
% Output files: CRUISE_Kd_PAR_BeamAtt.csv 
% Output Variable: Kd_obs = light attenuation coefficient during day time; 
% I0 = calculated PAR value jsut below the surface; 
% R2_PAR_Depth = R2 value of the linear regression between log(PAR) and Depth; 
% BeamAttm = Mean beam attenuation (At) in the upper 10m; 
% R2_Kd_BeamAtt = R2 value of the linear regression between Kd_obs and BeamAttm (1 value per cruise); 
% Kd_mdl = Light attenuation value obtained from the Kd vs. BeamAtt linear regression; 
% Kd = Final Kd value to use (K_obs during daytime, K_mdl during nighttime).
% 
% Authors: Pierre Marrec
% Created on 04/04/2022
%Modified on 11/28/2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars, clc, close all

%Set the directory where we work
rep = 'C:/Users/pierr/Desktop/PostDoc_URI_Desktop/NES-LTER/LTER_MLD_Kd_CTD/';
%URL of the REST-API
RESTAPI='https://nes-lter-data.whoi.edu/api/ctd/';
%Select the cruise you want. You need to create the corresponding folder in
%your directory
CRUISE={'en644';'en649';'en655';'ar39b';'en657';'en661';'en668';'ar61b';'at46';'en687'};

%Create  a cell to store the cast numbers of the different cruises
CAST=cell(length(CRUISE),1);

%Set the weboptions for downloading files as table
options = weboptions('ContentType', 'table');

%Get the cast numbers for each cruise
for n1=1:length(CRUISE)


    tablename1 = strcat(RESTAPI,CRUISE{n1},'/metadata.csv');
    mytable1 = webread(tablename1, options);
    C = mytable1.cast;

    CAST{n1}=C;

    clear mytable1

    %Create a table to store the Kd, Fluo and Beam attenuation values
    Results=table('Size',[length(CAST{n1}) 8],'VariableTypes',{'double','double',...
        'double','double','double','double','double','double'},...
        'VariableNames',{'cast','Kd_obs','I0','R2_PAR_Depth','BeamAttm','R2_Kd_BeamAtt','Kd_mdl','Kd'});

    if n1==3 %no CTD data for EN655 in the REST API, Data from R2R
        %https://www.rvdata.us/search/cruise/EN655
        %No CTD cast 12 and 15
        
        rep1 = strcat(rep,'en655/');%Where to get the raw pictures
        addpath(rep1)
        ext = '*.cnv';%File format
        chemin = fullfile(rep1,ext);
        list = dir(chemin);%List all cnv files in the directory

        for n2=1:numel(list)


            %load the .cnv files in a table format using the readCnv
            %function from US191/ctdPostProcessing
            %https://github.com/US191/ctdPostProcessing.git
            FileName=list(n2).name;
            C = strsplit(FileName,'_');
            CASTNb=C{1,2};
            castNb=str2double(CASTNb);
            

            T = readCnv(fullfile(rep1,list(n2).name));

            %get the depth, PAR and beam attenuation
            Depth=T.prDM;
            PAR=T.par;
            Beam=T.CStarTr0/100;
            
            %Get the Kd values mdl_slope when PAR>10, and the mean Fluo/Beam
            %attenuation

            %For most of the stations when depth>20-25m. By including
            %deeper PAR values, the linear relationship between depth and
            %log(PAR) is not good afetr depth >20m. Most of the light attenuation
            %occurs in the first 20m and constrain the Kd value
            if PAR(1,1)>10 && length(PAR)>=20
                mdl=fitlm(Depth(1:20),log(PAR(1:20)));
                mdl_R2=mdl.Rsquared.Ordinary;
                mdl_slope=mdl.Coefficients{2,1};
                mdl_intercept=mdl.Coefficients{1,1};

                Results.cast(n2)=castNb;
                Results.Kd_obs(n2)=-mdl_slope;
                Results.I0(n2)=exp(mdl_intercept);
                Results.R2_PAR_Depth(n2)=mdl_R2;

                a=find(Depth<11);

                Results.BeamAttm(n2)=mean(Beam(a),'omitnan');

                %For station with depth <20-25m, all the CTD values are
                %considered. It's a trcik to avoid considering variable length
                %of 20 when it's not the case.
            elseif PAR(1,1)>10 && length(PAR)<20

                mdl=fitlm(Depth,log(PAR));
                mdl_R2=mdl.Rsquared.Ordinary;
                mdl_slope=mdl.Coefficients{2,1};
                mdl_intercept=mdl.Coefficients{1,1};

                Results.cast(n2)=castNb;
                Results.Kd_obs(n2)=-mdl_slope;
                Results.I0(n2)=exp(mdl_intercept);
                Results.R2_PAR_Depth(n2)=mdl_R2;

                a=find(Depth<11);

                Results.BeamAttm(n2)=mean(Beam(a),'omitnan');

            else

                Results.cast(n2)=castNb;
                Results.Kd_obs(n2)=nan;
                Results.I0(n2)=nan;
                Results.R2_PAR_Depth(n2)=nan;

                a=find(Depth<11);

                Results.BeamAttm(n2)=mean(Beam(a),'omitnan');

            end

            clear T

        end

        %For all the other cruises
    else
        for n2=1:length(CAST{n1})
            cast=CAST{n1};

            %define the name of the csv file
            tablename2 = strcat(RESTAPI,CRUISE{n1},'/cast_',num2str(cast(n2)),'.csv');
            T = webread(tablename2, options);

            %get the depth, PAR, fluo and beam attenuation
            Depth=T.prdm;
            PAR=T.par;
            Beam=T.cstarat0;

            %set to zero PAR values <0
            p=find(PAR<0.00001);
            PAR(p)=nan;


            %Get the Kd values mdl_slope when PAR>10, and the mean Beam
            %attenuation

            %For most of the stations when depth>20-25m. By including
            %deeper PAR values, the linear relationship between depth and
            %log(PAR) is not good after depth >20m. Most of the light attenuation
            %occurs in the first 20m and constrain the Kd value
            if PAR(1,1)>10 && length(PAR)>=20
                mdl=fitlm(Depth(1:20),log(PAR(1:20)));
                mdl_R2=mdl.Rsquared.Ordinary;
                mdl_slope=mdl.Coefficients{2,1};
                mdl_intercept=mdl.Coefficients{1,1};

                Results.cast(n2)=cast(n2);
                Results.Kd_obs(n2)=-mdl_slope;
                Results.I0(n2)=exp(mdl_intercept);
                Results.R2_PAR_Depth(n2)=mdl_R2;

                a=find(Depth<11);

                Results.BeamAttm(n2)=mean(Beam(a),'omitnan');

                %For station with depth <20-25m, all the CTD values are
                %considered. It's a trcik to avoid considering variable length
                %of 20 when it's not the case.
            elseif PAR(1,1)>10 && length(PAR)<20

                mdl=fitlm(Depth,log(PAR));
                mdl_R2=mdl.Rsquared.Ordinary;
                mdl_slope=mdl.Coefficients{2,1};
                mdl_intercept=mdl.Coefficients{1,1};

                Results.cast(n2)=cast(n2);
                Results.Kd_obs(n2)=-mdl_slope;
                Results.I0(n2)=exp(mdl_intercept);
                Results.R2_PAR_Depth(n2)=mdl_R2;

                a=find(Depth<11);

                Results.BeamAttm(n2)=mean(Beam(a),'omitnan');

            else

                Results.cast(n2)=cast(n2);
                Results.Kd_obs(n2)=nan;
                Results.I0(n2)=nan;
                Results.R2_PAR_Depth(n2)=nan;

                a=find(Depth<11);

                Results.BeamAttm(n2)=mean(Beam(a),'omitnan');


            end

            clear table_ctd

        end

    end

    %Calculate Kd_mdl values from the linear regression between , when PAR<10 or when R2<0.7)
    b=find(Results.R2_PAR_Depth>0.7);

    mdl1=fitlm(Results.BeamAttm(b),Results.Kd_obs(b));
    mdl1_R2=mdl1.Rsquared.Ordinary;
    mdl1_slope=mdl1.Coefficients{2,1};
    mdl1_intercept=mdl1.Coefficients{1,1};
    Results.Kd_mdl=mdl1.Coefficients{2,1}*Results.BeamAttm+mdl1.Coefficients{1,1};
    %Store in the last Kd column, the Kd value (obs or mdl to use for a
    %given cast. If Kd_obs value available (daytime) with R2>0.7,
    %then Kd_obs value is conserved. If not, Kd_mdl is conserved.

    for n2=1:length(CAST{n1})

        Results.R2_Kd_BeamAtt(n2)=mdl1_R2;

        if Results.R2_PAR_Depth(n2)>0.7
            Results.Kd(n2)=Results.Kd_obs(n2);
        else
            Results.Kd(n2)=Results.Kd_mdl(n2);
        end



    end

    tablename3 = strcat(rep,CRUISE{n1},'_Kd_PAR_BeamAtt.csv');
    writetable(Results,tablename3)


end
