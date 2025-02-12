## Robust Bucket-Indexed Optimization

This repository contains the code for solving machine scheduling problems using a new robust optimization model based on the bucket-indexed mathematical formulation.  

We implement an ellipsoidal uncertainty set to represent uncertainties, based on the formulation presented in 
> Yankıoğlu, I., & Yavuz, T. (2022). Branch-and-price approach for robust parallel machine scheduling with sequence-dependent setup times. 
>  *European Journal of Operational Research,  301(3), 875-895*. [DOI: 10.1016/j.ejor.2021.11.023](https://doi.org/10.1016/j.ejor.2021.11.023)  

## Tested Instances  

A total of 56 instances from the authors' were tested. The original RMS dataset of instances can be found [here](https://www.ihsanyanikoglu.com/data-sets)


The tested instances belong to the *normal congestion* category, with:  
- m = \{4,6,8,10\} (number of machines)  
- r = \{2,3,4,5,6\} (ratio job-to-machine)  

## Instance Processing  

The script **read_dataset.jl** reads these instances and creates them as an `instanceRPMS` object, as defined in **instanceRPMS.jl**.

## Setup

A `requirements` file is provided to install all necessary dependencies to run the model.  
The implementation is written in **Julia**.  
The solver used is **Gurobi**.
