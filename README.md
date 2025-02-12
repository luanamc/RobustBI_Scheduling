# Robust Bucket-Indexed Optimization

This repository contains code for solving machine scheduling problems using a new robust optimization model based on the bucket-indexed mathematical formulation.

We implement an ellipsoidal uncertainty set to represent uncertainties, following the approach presented in:  
> Yankıoğlu, I., & Yavuz, T. (2022). Branch-and-price approach for robust parallel machine scheduling with sequence-dependent setup times.  
> *European Journal of Operational Research, 301(3), 875-895*. [DOI: 10.1016/j.ejor.2021.11.023](https://doi.org/10.1016/j.ejor.2021.11.023)

## Tested Instances

We tested a total of 56 instances from the authors. The original RMS dataset can be found [here](https://www.ihsanyanikoglu.com/data-sets).

These instances belong to the *normal congestion* category, with the following parameters:  
- m = \{4,6,8,10\} (number of machines)  
- r = \{2,3,4,5,6\} (job-to-machine ratio)

### Instance Processing

The **read_dataset.jl** script loads these instances and creates an `instanceRPMS` object, as defined in **instanceRPMS.jl**.

## Robust Formulations Implementation

The **robust_models.jl** file includes the implementation of the two models used for result comparison:  
- **Continuous formulation**, based on the aforementioned paper  
- **Bucket-Indexed formulation**, the new model proposed in this paper

## Other Shared Files

- **param**: Parameter struct defining model execution settings  
- **export_results**: Auxiliary functions for exporting optimization results  
- **main**: Script to execute the optimization model

## Setup

A `requirements` file is provided for easy installation of all dependencies.  
This implementation is written in **Julia** and uses the **Gurobi** solver.
