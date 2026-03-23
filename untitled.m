clear; clc; close all;

%% Thong so bai toan
Fs = 32000;          % tan so lay mau
nbits = 8;           % 8 bit / mau khi ghi am
nch = 1;             % mono
T = 10;              % 10 giay
delta = 0.03;        % buoc DM (co the chinh 0.02 -> 0.05)
smoothN = 8;         % cua so lam muot sau giai ma

%% 1) Ghi am
recObj = audiorecorder(Fs, nbits, nch);

disp('Bat dau ghi am 10 giay...');
recordblocking(recObj, T);
disp('Da ghi xong.');

x = getaudiodata(recObj, 'double');   % lay du lieu dang double
x = x(:);                             % dam bao la cot

%% 2) Tien xu ly
x = x - mean(x);                      % bo DC
mx = max(abs(x));
if mx > 0
    x = x / mx;                       % chuan hoa ve [-1,1]
end

N = length(x);

%% 3) Ma hoa Delta Modulation (1 bit / mau)
bits = false(N,1);    % luu 0/1
xhat = zeros(N,1);    % tin hieu tai tao trong bo ma hoa

% Khoi tao mau dau
if x(1) >= 0
    bits(1) = true;
    xhat(1) = delta;
else
    bits(1) = false;
    xhat(1) = -delta;
end

for n = 2:N
    if x(n) >= xhat(n-1)
        bits(n) = true;              % bit = 1 -> tang len
        xhat(n) = xhat(n-1) + delta;
    else
        bits(n) = false;             % bit = 0 -> giam xuong
        xhat(n) = xhat(n-1) - delta;
    end

    % gioi han bien do
    if xhat(n) > 1
        xhat(n) = 1;
    elseif xhat(n) < -1
        xhat(n) = -1;
    end
end

%% 4) Luu file .mat
% bits la bitstream 1 bit/mau ve mat mo hinh
save('dm_encoded.mat', 'bits', 'Fs', 'delta', 'T');

%% 5) Giai ma lai tu bitstream
y = zeros(N,1);

if bits(1)
    y(1) = delta;
else
    y(1) = -delta;
end

for n = 2:N
    if bits(n)
        y(n) = y(n-1) + delta;
    else
        y(n) = y(n-1) - delta;
    end

    if y(n) > 1
        y(n) = 1;
    elseif y(n) < -1
        y(n) = -1;
    end
end

%% 6) Lam muot de nghe lai de hon
% DM giai ma thuong ra dang bac thang, nghe se rat "gai".
% Dung movmean de lam muot nhe, khong can toolbox them.
y_rec = movmean(y, smoothN);

% Chuan hoa truoc khi ghi wav
y_rec = y_rec - mean(y_rec);
my = max(abs(y_rec));
if my > 0
    y_rec = 0.98 * y_rec / my;
end

%% 7) Ghi file wav phuc hoi
audiowrite('dm_reconstructed.wav', y_rec, Fs);

disp('Da tao 2 file can nop:');
disp('1) dm_encoded.mat');
disp('2) dm_reconstructed.wav');

%% 8) Nghe thu
sound(y_rec, Fs);

%% 9) Ve hinh de bao cao (neu can)
t = (0:N-1)/Fs;

figure;
subplot(3,1,1);
plot(t, x);
title('Tin hieu goc');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

subplot(3,1,2);
stairs(t, double(bits));
title('Bitstream DM (1 bit/mau)');
xlabel('Time (s)'); ylabel('Bit'); grid on;

subplot(3,1,3);
plot(t, y_rec);
title('Tin hieu phuc hoi');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;