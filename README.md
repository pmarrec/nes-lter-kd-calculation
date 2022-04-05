# nes-lter-kd-calculation

Matlab code and output csv files for the automated caluclation of light attenuation coefficient for NES-LTER cruises.

Light attenuation coefficient (Kd_obs) are calculated from the linear regression between depth and the corresponding log value of PAR during daytime casts (PAR >10 umol photons m-2 s-1), when the observed R2 was higher than 0.70.

R2 values < 0.70 resulted of a substantial ship shading.

Mean beam attenuation (At) in the upper 10m was calculated for each cast and a relationship (linear regression) was established between mean beam attenuation and Kd_obs for each cast.

During nighttime casts, Kd_mdl (modeled Kd) was estiamted from the average beam attenuation in the upper 10 m using the slope and intercept from equation:
Kd_mdl = m * At + b

For Ar39b, no significant linear relationship between Kd and Beam Attenuation (At) was retrieved because of technical problem with the transmitter. No Kd_mdl value was calculated for this cruise.

The final Kd to use as light attenuation coefficient is indicated in the last column of the output file. It corresponds to the Kd value obtained during daytime casts (if R2 log(PAR) vs. Depth >0.70) or to the Kd values obatined from nighttime cast from the Beam Attenuation (or if daytime R2 log(PAR) vs. Depth <0.70).

Input files: REST-API CTD csv files or local ascii files for en655 and REST-API CTD metadata providing a list of casts for a given cruise.
Input variable: PrDM = CTD Depth; Par = CTD PAR; CStarAt0 = CTD Beam Attenuation.

Output files: CRUISE_Kd_PAR_BeamAtt.csv
Output Variable: Kd_obs = light attenuation coefficient during day time; I0 = calculated PAR value jsut below the surface; R2_PAR_Depth = R2 value of the linear regression between log(PAR) and Depth; BeamAttm = Mean beam attenuation (At) in the upper 10m;  R2_Kd_BeamAtt = R2 value of the linear regression between Kd_obs and BeamAttm (1 value per cruise); Kd_mdl = Light attenuation value obtained from the Kd vs. BeamAtt linear regression; Kd = Final Kd value to use (K_obs during daytime, K_mdl during nighttime). 
