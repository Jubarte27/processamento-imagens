classdef gabor

    properties (SetAccess = immutable)
        Wavelength
        Orientation
        SpatialAspectRatio
        SpatialFrequencyBandwidth
    end

    properties (Dependent = true, Hidden = true)
        KernelSize
    end

    % The SpatialKernel is only computed as needed
    properties (Dependent)
        SpatialKernel
    end

    properties (Access = private, Dependent = true)
        SigmaX
        SigmaY
        Rx
        Ry
    end

    methods

        function self = gabor(varargin)

            if (nargin > 0)
                results = struct('Wavelength', double(varargin{1}), 'Orientation', double(varargin{2}), 'SpatialFrequencyBandwidth', 1.0, 'SpatialAspectRatio', 0.5);
                results = computeParameterCombinations(results);
                numFilters = length(results.Orientation);
                % Use default construct to allocate vector of gabor filter
                % instances.
                self(numFilters) = gabor(); %#ok<*EMVDF>

                for n = 1:numFilters
                    self(n).Wavelength = results.Wavelength(n);
                    self(n).Orientation = results.Orientation(n);
                    self(n).SpatialAspectRatio = results.SpatialAspectRatio(n);
                    self(n).SpatialFrequencyBandwidth = results.SpatialFrequencyBandwidth(n);
                end

            else
                % Default constructor
                self.Wavelength = 4;
                self.Orientation = 0;
                self.SpatialAspectRatio = 0.5;
                self.SpatialFrequencyBandwidth = 1.0;
            end

        end

        function sigmaX = get.SigmaX(self)
            % From relationship in "Nonlinear Operator in Oriented Texture", Kruizinga,
            % Petkov, 1999.
            BW = self.SpatialFrequencyBandwidth;
            sigmaX = self.Wavelength / pi * sqrt(log(2) / 2) * (2 ^ BW + 1) / (2 ^ BW - 1);
        end

        function sigmaY = get.SigmaY(self)
            sigmaY = self.SigmaX ./ self.SpatialAspectRatio;
        end

        function rx = get.Rx(self)
            % SpatialKernel needs large (7 sigma radial) falloff of
            % Gaussian in spatial domain for frequency domain and spatial
            % domain computations to be equivalent within floating point
            % round off error.
            rx = ceil(7 * self.SigmaX);
        end

        function ry = get.Ry(self)
            ry = ceil(7 * self.SigmaY);
        end

        function kSize = get.KernelSize(self)
            r = max(self.Rx, self.Ry);
            kSize = [2 * r + 1, 2 * r + 1];
        end

        function h = get.SpatialKernel(self)

            % Parameterization of spatial kernel frequency includes Phi as
            % an independent variable. We use a constant of 0.
            phi = 0;

            sigmax = self.SigmaX;
            sigmay = self.SigmaY;

            r = max(self.Rx, self.Ry);

            [X, Y] = meshgrid(-r:r, -r:r);

            Xprime = X .* cosd(self.Orientation) - Y .* sind(self.Orientation);
            Yprime = X .* sind(self.Orientation) + Y .* cosd(self.Orientation);

            hGaussian = exp(-1/2 * (Xprime .^ 2 ./ sigmax ^ 2 + Yprime .^ 2 ./ sigmay ^ 2));
            hGaborEven = hGaussian .* cos(2 * pi .* Xprime ./ self.Wavelength + phi);
            hGaborOdd = hGaussian .* sin(2 * pi .* Xprime ./ self.Wavelength + phi);

            h = complex(hGaborEven, hGaborOdd);

        end

    end

    methods (Hidden = true)

        function H = makeFrequencyDomainTransferFunction(self, imageSize, classA)

            % Directly construct frequency domain transfer function of
            % Gabor filter. (Jain, Farrokhnia, "Unsupervised Texture
            % Segmentation Using Gabor Filters", 1999)
            M = imageSize(1);
            N = imageSize(2);
            u = cast(createNormalizedFrequencyVector(N), classA);
            v = cast(createNormalizedFrequencyVector(M), classA);
            [U, V] = meshgrid(u, v);

            Uprime = U .* cosd(self.Orientation) - V .* sind(self.Orientation);
            Vprime = U .* sind(self.Orientation) + V .* cosd(self.Orientation);

            sigmau = 1 / (2 * pi * self.SigmaX);
            sigmav = 1 / (2 * pi * self.SigmaY);
            freq = 1 / self.Wavelength;

            A = 2 * pi * self.SigmaX * self.SigmaY;

            H = A .* exp(-0.5 * (((Uprime - freq) .^ 2) ./ sigmau ^ 2 + Vprime .^ 2 ./ sigmav ^ 2));

        end

    end

end

function resultsOut = computeParameterCombinations(results)

    [lambda, theta, bandwidth, spatialAspectRatio] = ...
        ndgrid(results.Wavelength, results.Orientation, results.SpatialFrequencyBandwidth, results.SpatialAspectRatio);

    resultsOut = struct('Wavelength', lambda(:), ...
        'Orientation', theta(:), ...
        'SpatialFrequencyBandwidth', bandwidth(:), ...
        'SpatialAspectRatio', spatialAspectRatio(:));

end

function u = createNormalizedFrequencyVector(N)

    if mod(N, 2)
        u = linspace(-0.5 + 1 / (2 * N), 0.5 - 1 / (2 * N), N);
    else
        u = linspace(-0.5, 0.5 - 1 / N, N);
    end

end
