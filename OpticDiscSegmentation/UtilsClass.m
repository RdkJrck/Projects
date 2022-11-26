%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : DOPLNIT
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne

classdef UtilsClass
%%%% Class UtilsClass
%%  Class responsible for conversion of parameters from and to parametric and normalized space.

    properties
    end
    
    methods
        function [ params ] = para2norm(self, ga_config, para_space_params)
        %%%% Function para2norm
        %%  Converts parameters from parametric to normalized space.
        %%
        %%  :param ga_config: structure with genetic algorithm configuration
        %%  :param para_space_params: parametric parameters
        %%  :return params: normalized parameters

            params = (para_space_params - ga_config.lower_bound) ./ (ga_config.upper_bound - ga_config.lower_bound);
        end

        function [ params ] = norm2para(self, ga_config, norm_space_params)
        %%%% Function norm2para
        %%  Converts parameters from normalized to parametric space.
        %%
        %%  :param ga_config: structure with genetic algorithm configuration
        %%  :param norm_space_params: normalized parameters
        %%  :return params: parametric parameters

            params = ga_config.lower_bound + norm_space_params .* (ga_config.upper_bound - ga_config.lower_bound);
            params(ga_config.round_params == 1) = round(params(ga_config.round_params == 1));
            
            params(ga_config.odd_params == 1) = 2 * floor(params(ga_config.odd_params == 1) / 2) + 1;
            params(ga_config.even_params == 1) = 2 * round(params(ga_config.even_params == 1) / 2);
        end
    end
end
