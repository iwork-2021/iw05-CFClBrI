# iw05
iOS assignment 5: Object Detection App.

作业 4-1 
  请基于模板工程(ObjectDetection)，运用CoreML开发一个利用TinyYOLO进行目标检测的iOS App。

功能要求如下：

1. 通过TuriCreate，基于snacks数据集训练目标检测模型
2. 运用摄像头功能，利用训练好的模型进行实时的目标检测，支持多目标检测
3. 在屏幕上展示神经网络模型的分类结果和目标框(bounding box)

非必要功能需求如下：

1. 可调iouThreshold和confidenceThreshold
2. 熟悉YOLOv X模型

操作流程简介

0. 安装python（mac环境不需要，自带了）

1. 安装conda（可以通过pip install）

2. 安装conda环境：turienv.yaml是conda环境需求文件，通过一下命令安装环境
```python
conda env create -f turienv.yaml
```
3. 安装jupyter notebook
  
  通过conda安装
  ```python
  conda install -c conda-forge notebook
  ```
  通过pip安装
  ```python
  pip install notebook
  ```
  安装好后，在终端运行
  ```terminal
  jupyter notebook
  ```
  
4. 执行tinyYOLO.ipynb
