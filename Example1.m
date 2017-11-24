% Create a set of track gains according to vMF distribution
%
% Created: 24/Nov/2017 by Alex Wilson
%
% REFERENCES:
% [1]. Pestana, P.D., Reiss, J.D. and Barbosa, A., 2013, May. Loudness measurement of multitrack audio content using modifications of ITU-R BS. 1770. In Audio Engineering Society Convention 134.
% [2]. Pestana, 2013. "Automatic mixing systems using adaptive digital audio effects".
% [3]. Wilson, 2017, "Evaluation and Modelling of Perceived Audio Quality in Popular Music, towards Intelligent Music Production")
%
clear all
close all

% required --- (available from https://github.com/yuhuichen1015/SphericalDistributionsRand)
addpath(genpath('C:\Program Files\MATLAB\R2016a\toolbox\SphericalDistributionsRand'));

%% Import test audio

% test audio comprises of 8 tracks, 30s in duration and normalised
% in perceived loudness (according to [1].)

tracknames = {'OH1','OH2','Kick','Snare','Bass','Gtr1','Gtr2/Piano','Vox'};
folder = 'Audio\WIW';
  
listing = dir(strcat(folder,'\*.wav'));
for i = 1:length(listing);
   files{i} = listing(i).name;
end
clear i
currentf = cd(folder);
for i = 1:length(files)
    %[audio.tracks(:,i), audio.fs, audio.nbits] = wavread(files{i});        % for older versions of MATLAB
    [audio.tracks(:,i)] = audioread(files{i});
    temp = audioinfo(files{i});
    audio.fs = temp.SampleRate;
    audio.nbits = temp.BitsPerSample;
end
clear i
cd(currentf)
 
nTracks = length(files);
clear listing folder currentf files temp

%% Generate mixes
%nTracks = 8;
nMixes = 1000;
kappa = 200;

balanced_gains = repmat(1/sqrt(nTracks),[1 nTracks]);

% mixes with vocal boost (according to [2]. )
vocal_track = 8;
vocal_boost = balanced_gains;
vocal_boost(vocal_track) = balanced_gains(8) *(10^(6.54/20));         % add boost to vocal track
vocal_boost = bsxfun(@rdivide,vocal_boost,norm(vocal_boost));

% mixes based on perceptual experiment (according to [3].)
informed_gains = [0.2254 0.2282 0.3221 0.2679 0.4437 0.3616 0.3221 0.5387]; % from experimental result

mu = [ vocal_boost; informed_gains];

figure()
    bar(20*log10(mu'));
    ylabel('Gain (dBFS)')
    xlabel('Track')
    set(gca,'xticklabels',tracknames)
    legend('Vocal boost model','Perceptual model','location','southeast')

X = zeros([nMixes nTracks 2]);

X(:,:,1) = randVMF(nMixes,mu(1,:),kappa);
X(:,:,2) = randVMF(nMixes,mu(2,:),kappa);

figure()
    subplot(1,2,1)
        boxplot(X(:,:,1))
        axis([0.5 8.5 -0.1 1])
        ylabel('Gain')
        set(gca,'xticklabels',tracknames)
        
    subplot(1,2,2)
        boxplot(X(:,:,2))
        axis([0.5 8.5 -0.1 1])
        ylabel('Gain')
        set(gca,'xticklabels',tracknames)
        
%% choose a mix at random and listen
mixidx = randi(nMixes,1);

%generate mix from audio and gains
mix_gain = X(mixidx,:,2);
mix = audio.tracks*mix_gain';     

player = audioplayer(mix,audio.fs,audio.nbits);
play(player);

figure()
subplot(1,2,1)
    xax = (1:length(audio.tracks))./audio.fs;
    plot(xax,mix)
    axis([-inf inf -1 1])
    xlabel('Time (s)')
    ylabel('Normalised Sample Amplitude')
subplot(1,2,2)
    bar(20*log10(mix_gain))
    ylabel('Gain (dBFS)')
    xlabel('Track')
    set(gca,'xticklabels',tracknames)
    axis([0.5 8.5 -inf 0])
