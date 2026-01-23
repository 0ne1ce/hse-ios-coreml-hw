import torch
import torch.nn as nn
import torchvision
import coremltools as ct
import urllib.request

model = torchvision.models.squeezenet1_1(weights=torchvision.models.SqueezeNet1_1_Weights.IMAGENET1K_V1)
model.eval()


class SqueezeNetWithSoftmax(nn.Module):
    def __init__(self, base_model):
        super().__init__()
        self.base = base_model
        self.softmax = nn.Softmax(dim=1)

    def forward(self, x):
        x = self.base(x)
        return self.softmax(x)


model_with_softmax = SqueezeNetWithSoftmax(model)
model_with_softmax.eval()

traced = torch.jit.trace(model_with_softmax, torch.rand(1, 3, 224, 224))

urllib.request.urlretrieve("https://raw.githubusercontent.com/pytorch/hub/master/imagenet_classes.txt", "labels.txt")
with open("labels.txt") as f:
    labels = [line.strip() for line in f]

mlmodel = ct.convert(
    traced,
    inputs=[ct.ImageType(name="image", shape=(1, 3, 224, 224), scale=1 / 255.0,
                         bias=[-0.485 / 0.229, -0.456 / 0.224, -0.406 / 0.225], color_layout=ct.colorlayout.RGB)],
    classifier_config=ct.ClassifierConfig(labels),
    minimum_deployment_target=ct.target.iOS15
)

mlmodel.save("SqueezeNet.mlpackage")
print("Success")