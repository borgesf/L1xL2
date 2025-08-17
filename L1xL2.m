%% L1_vs_L2
% L1 vs L2 global-shift demo
%
% PURPOSE
%   - Create a synthetic "true" depth surface (a smooth horizon).
%   - Generate a seismic-derived estimate by sampling the true surface
%     and adding small random perturbations (to mimic imperfect prediction).
%   - Sample a sparse set of well locations and produce "measured" depths by
%     adding measurement noise and a small fraction of large outliers.
%   - Compute the residuals r_i = measured_depth - seismic_estimate_at_well.
%   - Compute a global L2 correction (mean of residuals) and an L1 correction
%     (median of residuals). Apply both corrections to the seismic estimate.
%   - Plot three well-scatter maps (original residuals, L2-corrected residuals,
%     L1-corrected residuals) and a histogram comparing distributions.
%
% USAGE
%   Run the script in MATLAB (R2018+). No extra toolboxes are required.
%   Output: figure 'L1_vs_L2_clean_documented.png' is saved in current folder.
%
% AUTHOR
%   Filipe Borges

clear; close all; clc;
rng(0);  % reproducible example

%% ------------------------------------------------------------------------
% 1) Define spatial domain and create the "true depth" surface
% -------------------------------------------------------------------------
% Domain: regular grid in kilometers (east, north)
nx = 101;
ny = 101;
easting_km  = linspace(0, 10, nx);   % X axis (km)
northing_km = linspace(0, 10, ny);   % Y axis (km)
[EAST, NORTH] = meshgrid(easting_km, northing_km);   % grid for plotting

% True (reference) horizon depth in meters.
% This is the 'ground truth' surface we will sample from for wells.
true_depth = 2000 ...                        % base depth (m)
    + 8 * sin(2 * pi * EAST / 10) ...        % gentle variation with X
    + 5 * cos(2 * pi * NORTH / 10) ...       % gentle variation with Y
    + 0.5 * EAST .* NORTH;                   % slight XY interaction (tilt)

%% ------------------------------------------------------------------------
% 2) Create a seismic-derived estimate of the horizon
%    (seismic_estimate = true_depth + small random perturbation)
% -------------------------------------------------------------------------
% NOTE: we are NOT adding a 'bias' here. We simply perturb the true surface
% slightly to simulate that seismic-derived predictions are imperfect.
noise_amplitude = 0.8;  % standard deviation of small prediction noise (meters)
seismic_estimate = true_depth + noise_amplitude * randn(size(true_depth));

% (Optional) If you prefer perfectly smooth seismic estimate, replace above with:
% seismic_estimate = true_depth;

%% ------------------------------------------------------------------------
% 3) Sample wells and produce 'measured' depths (truth + measurement noise)
% -------------------------------------------------------------------------
% Number of wells to sample (sparse sampling typical of wells)
Nwells = 20;

% Random well coordinates in the same domain (units: km)
well_easting_km  = 10 * rand(Nwells, 1);
well_northing_km = 10 * rand(Nwells, 1);

% Map continuous coordinates to nearest grid indices (uniform grid assumption)
dx = easting_km(2) - easting_km(1);
dy = northing_km(2) - northing_km(1);

ix = round((well_easting_km - easting_km(1)) / dx) + 1;  % 1-based index
ix = min(max(ix, 1), nx);

iy = round((well_northing_km - northing_km(1)) / dy) + 1;
iy = min(max(iy, 1), ny);

% Linear index into the 2D arrays (row-major: iy, ix corresponds to (north,east))
well_linear_idx = sub2ind(size(true_depth), iy, ix);

% Measured well depth: start from the true depth at that location
measurement_noise_std = 5;                     % typical measurement scatter (m)
measurement_noise = measurement_noise_std * randn(Nwells, 1);

measured_depth = true_depth(well_linear_idx) + measurement_noise;

% Inject a small fraction of large outliers to simulate bad well measurements
outlier_fraction = 0.1;                      % 10% of wells are problematic
nout = max(1, round(outlier_fraction * Nwells));
outlier_indices = randperm(Nwells, nout);

% Add large random offsets to outlier wells (positive biases here, could be negative)
for k = 1 : nout
    i = outlier_indices(k);
    measured_depth(i) = measured_depth(i) + (50 + 30 * randn());  % large error ~ N(50,30)
end

%% ------------------------------------------------------------------------
% 4) Compute residuals at well locations
%    residual = measured_depth - seismic_estimate_at_well
% -------------------------------------------------------------------------
seismic_at_wells = seismic_estimate(well_linear_idx);
residuals_at_wells = measured_depth - seismic_at_wells;   % r_i = measured - seismic

% Print quick summary of residual stats 
fprintf('Wells: %d, outliers injected: %d (%.1f%%)\n', Nwells, nout, 100 * nout / Nwells);
fprintf('Residuals: mean=%.3f m, median=%.3f m, std=%.3f m\n', ...
    mean(residuals_at_wells), median(residuals_at_wells), std(residuals_at_wells));
fprintf('Residuals: min=%.3f m, max=%.3f m\n', min(residuals_at_wells), max(residuals_at_wells));

%% ------------------------------------------------------------------------
% 5) Compute L2 and L1 single-number global shifts
%    - L2 shift (mean) minimizes sum of squared residuals
%    - L1 shift (median) minimizes sum of absolute residuals
% -------------------------------------------------------------------------
shift_L2 = mean(residuals_at_wells);    % L2 solution (global shift)
shift_L1 = median(residuals_at_wells);  % L1 solution (global shift)

fprintf('Shift L2 (mean) = %.3f m\n', shift_L2);
fprintf('Shift L1 (median) = %.3f m\n', shift_L1);

% Apply each shift to the entire seismic estimate (what you'd do to correct predictions)
seismic_corrected_L2 = seismic_estimate + shift_L2;
seismic_corrected_L1 = seismic_estimate + shift_L1;

% Compute the post-correction errors at wells (what you'd actually observe)
err_orig = measured_depth - seismic_at_wells;                    % original residuals
err_after_L2 = measured_depth - (seismic_at_wells + shift_L2);  % after L2 correction
err_after_L1 = measured_depth - (seismic_at_wells + shift_L1);  % after L1 correction

% Performance metrics (useful for comparison)
MAE_orig  = mean(abs(err_orig));    RMSE_orig  = sqrt(mean(err_orig.^2));
MAE_L2    = mean(abs(err_after_L2)); RMSE_L2    = sqrt(mean(err_after_L2.^2));
MAE_L1    = mean(abs(err_after_L1)); RMSE_L1    = sqrt(mean(err_after_L1.^2));

%% ------------------------------------------------------------------------
% 6) Plot clean visualizations: wells only (no background), histograms, and metrics
% -------------------------------------------------------------------------
% Make a simple diverging colormap (blue-white-red)
ncol = 256;
half = round(ncol/2);
r = [linspace(0,1,half)'; ones(ncol-half,1)];
g = [linspace(0,1,half)'; linspace(1,0,ncol-half)'];
b = [ones(half,1); linspace(1,0,ncol-half)'];
div_cmap = [r g b];

% Create figure layout
figure('Units','normalized', 'Position', [0.05 0.08 0.9 0.75]);
tiledlayout(2,3, 'TileSpacing','compact', 'Padding','compact');

% Fixed symmetric color axis for the well-maps (meters)
fixed_color_min = -10;
fixed_color_max = 10;

% Panel 1: Original residuals at wells (clean scatter)
nexttile([1 1]);
scatter(well_easting_km, well_northing_km, 80, err_orig, 'filled', 'MarkerEdgeColor','k', 'LineWidth',0.6);
colormap(div_cmap); clim([fixed_color_min fixed_color_max]); axis equal;
xlim([min(easting_km) max(easting_km)]); ylim([min(northing_km) max(northing_km)]);
xlabel('Easting (km)'); ylabel('Northing (km)');
title('Original residuals at wells', 'FontSize', 11);
cb = colorbar; ylabel(cb, 'Residual (m)');
cb.Ticks = fixed_color_min : 5 : fixed_color_max;
set(gca, 'Box', 'on'); grid on;

% Panel 2: Residuals after L2 global shift
nexttile;
scatter(well_easting_km, well_northing_km, 80, err_after_L2, 'filled', 'MarkerEdgeColor','k', 'LineWidth',0.6);
colormap(div_cmap); clim([fixed_color_min fixed_color_max]); axis equal;
xlim([min(easting_km) max(easting_km)]); ylim([min(northing_km) max(northing_km)]);
xlabel('Easting (km)'); ylabel('Northing (km)');
title(sprintf('After L2 shift (%.2f m)', shift_L2), 'FontSize', 11);
cb = colorbar; ylabel(cb, 'Residual (m)');
cb.Ticks = fixed_color_min : 5 : fixed_color_max;
set(gca, 'Box', 'on'); grid on;

% Panel 3: Residuals after L1 global shift
nexttile;
scatter(well_easting_km, well_northing_km, 80, err_after_L1, 'filled', 'MarkerEdgeColor','k', 'LineWidth',0.6);
colormap(div_cmap); clim([fixed_color_min fixed_color_max]); axis equal;
xlim([min(easting_km) max(easting_km)]); ylim([min(northing_km) max(northing_km)]);
xlabel('Easting (km)'); ylabel('Northing (km)');
title(sprintf('After L1 shift (%.2f m)', shift_L1), 'FontSize', 11);
cb = colorbar; ylabel(cb, 'Residual (m)');
cb.Ticks = fixed_color_min : 5 : fixed_color_max;
set(gca, 'Box', 'on'); grid on;

% Panel 4-5: Histogram comparing original vs corrected residual distributions
nexttile([1 2]);
edges = -100 : 5 : 100;  % round bins
histogram(err_orig, edges, 'Normalization', 'pdf', 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', 'none'); hold on;
histogram(err_after_L2, edges, 'Normalization', 'pdf', 'FaceColor', [0 0.4470 0.7410], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
histogram(err_after_L1, edges, 'Normalization', 'pdf', 'FaceColor', [0.8500 0.3250 0.0980], 'FaceAlpha', 0.6, 'EdgeColor', 'none');
xlabel('Residual (m)'); ylabel('Density'); title('Residual distributions at wells (measured - predicted)');
legend('Original', 'After L2', 'After L1', 'Location', 'northeast');
xlim([-100 100]);
ylim([0 0.10]);
yticks(0 : 0.05 : 0.10);
grid on; box on;

set(findall(gcf, '-property', 'FontName'), 'Fontsize', 14)

% Panel 6: Text summary of metrics 
nexttile;
axis off;
metrics_text = {
    sprintf('N wells = %d', Nwells)
    sprintf('Outliers injected = %d (%.1f%%)', nout, 100 * nout / Nwells)
    ''
    sprintf('Residual mean = %.2f m', mean(residuals_at_wells))
    sprintf('Residual median = %.2f m', median(residuals_at_wells))
    sprintf('Residual std = %.2f m', std(residuals_at_wells))
    ''
    sprintf('MAE original = %.2f m', MAE_orig)
    sprintf('MAE after L2 = %.2f m', MAE_L2)
    sprintf('MAE after L1 = %.2f m', MAE_L1)
    ''
    sprintf('RMSE original = %.2f m', RMSE_orig)
    sprintf('RMSE after L2 = %.2f m', RMSE_L2)
    sprintf('RMSE after L1 = %.2f m', RMSE_L1)
    };


text(0.02, 0.98, metrics_text, 'VerticalAlignment', 'top', 'FontName', 'Consolas', 'FontSize', 11);
set(findall(gcf, '-property', 'FontName'), 'FontName', 'Helvetica')
% Save figure

set(gcf, 'Color', 'w');
exportgraphics(gcf, 'L1_vs_L2_plot.png', 'Resolution',400);



%% ------------------------------------------------------------------------
% 7) Short textual interpretation 
% -------------------------------------------------------------------------
fprintf('\nInterpretation (copy/paste):\n');
fprintf(' - L2 (mean) minimizes squared error (RMSE) and is pulled toward large outliers.\n');
fprintf(' - L1 (median) minimizes absolute error (MAE) and is robust to outliers.\n');
fprintf(' - Use L1 when you want resilience to a few problematic wells; use L2 when you\n   expect errors to be roughly Gaussian and you wish to heavily penalize large misfits.\n');

