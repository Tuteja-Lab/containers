# Container properties

## packages
See list of R, python, and aptitude packages installed in the respective text files (current folder)

## building

Note: you need to run this on your local machine where you have sudo access. You will also need to install Docker and Singularity for the commands to work.

```bash
sudo docker build -t rstudio:4.2.2  -f Dockerfile .
sudo singularity build rstudio-4.2.2.sif docker-daemon://rstudio:4.2.2
```

