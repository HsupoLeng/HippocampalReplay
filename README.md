# HippocampalReplay
This repository holds the code for a project exploring navigation- and memory-related neural activities in the hippocampus. The project is a collaboration between Xubo Leng and Yixiu Liu, both graduate students at UCSD at the time of this project. 

Programs in this repository include our implementations of standard routines to detect place cells and sharp wave ripples (SWRs). We hypothesize that the place fields of neurons that spike during SWRs indicate the rat’s future navigational decision in an alternation task. To test this hypothesis, a place field superimposition algorithm for navigational decision prediction is proposed. We observed higher than theoretical chance level (50%) predictability in some cases. Variability in prediction accuracy might be explained by variability in the rat's own performance. Code to characterize rat's performance is also included. 

The dataset we use is collected by Karlsson et al. [\[1\]](http://crcns.org/data-sets/hc/hc-6) at the Loren Frank lab at UCSF. The behaviour task is described in Karlsson and Frank's paper [\[2\]](https://www.nature.com/articles/nn.2344) and Singer et al.'s paper [\[3\]](https://www.sciencedirect.com/science/article/pii/S0896627313000937?via%3Dihub), both of which were important references for our project. 

## Running the code
Names of most programs in this repository indicate their respective purposes. To run the prediction algorithm, run the script `run_predict_location_with_place_cell_firing_map` in MATLAB. 

## Related material
For an overview of the project, see the [presentation](https://drive.google.com/open?id=11q5c6uf_kDDwtQPS7ICLhBfLMbhvM9NJ) prepared by Yixiu and me; for more details, refer to [our project report](https://drive.google.com/open?id=1FlzVi7bptmzZ2e-BIrKuq04Ur7wImdgg). 

