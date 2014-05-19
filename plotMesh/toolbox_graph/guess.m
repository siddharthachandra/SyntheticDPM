%% preparation. getting fronto parallel.
y = -0.19;
p = -0.71;
r = 4.99;
addpath off
addpath toolbox
load vertices.mat
load faces.mat
R = angle2dcm(y,p,r);
v = v*R;
set(gcf, 'InvertHardcopy', 'off');
colordef black;
%% prepared.
set(0,'DefaultFigureColor',[0 0 0]);
% enumerating unit vectors
    gridSize = 3;
    uVs = getUnitVectors(gridSize);
    nuVs = size(uVs,1);
    % enumerating angles
    angles = linspace(0,pi/6,10);
    numangles = length(angles);
%% side-face
for face = 1:4,
    switch face
        case 1 %front
            angle = 0;
        case 2 %rear
            angle = 180;
        case 3 %profile1
            angle = 90;
        case 4 %profile2
            angle = -90;
    end
    angle = angle*(pi/180);
    %%  projecting to face
    Xaxis = [0 1 0];
    rotationM = compute_rotation(Xaxis,angle);
    v2 = v*rotationM;
    %% projected
    
    for uVid = 1:nuVs,
        for angleid = 1:numangles,
            rotationMAT = compute_rotation(uVs(uVid,:),angles(angleid));
            v3 = v2*rotationMAT;
            depths = v3(:,3);
            depthcolor = [depths depths depths];
            options.face_vertex_color = mat2gray(depths);
            plot_mesh(v3,f,options);
            print('-dpng',sprintf('s.f%d.u%d.a%d.png',face,uVid,angleid)); return;
            clf;
        end
    end
end
