# A simplified Bueno de Mesquita's model for The Predictioneer's Game

Full model description and validation results see [here](https://blksv.dev/posts/prediction/mesquita-simplified).

While being _very_ simple, it performs on par with [this Mesquita's model](https://www.incidepro.us/documents/CMPS_NewModel.pdf) _(Bueno de Mesquita, B. (2011). A New Model for Predicting Policy Choices: Preliminary Tests. Conflict Management and Peace Science, 28(1), 65-87)_ on the ["EU Decides" dataset](https://doi.org/10.34810/data53) _(Arregui, J. & Perarnaud, C. (2021). "A new dataset on legislative decision-making in the European Union: the DEU III dataset")_.

The `deu3.csv` contains the above validation dataset with GDPs (the second line) added and invalid outcome values removed, `model.nim` contains the implementation of the model, `validation.nim` runs the validation process and `main.nim` runs the model on the input file provided in the command line args. `input.dat` is a sample input file.

The command line usage is `main [--runs|-r:nRuns] [--log:logFile] [--results:resultsFile] inputFile`

When specified, the results file will contain a sorted list of predicted outcomes to assess the distribution of results. The log file will contain information about all the contests. It's better not to use it with large `nRuns`, as it is very verbose.
