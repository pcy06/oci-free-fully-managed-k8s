# OCI Free Fully managed k8s Cluster
OCI의 혜자 무료 리소스를 극한으로 뽑아 완전관리형 쿠버네티스 클러스터를 만들어 주는 IaC 코드

## 이 코드가 하는 일
이 코드는 OCI에서 제공하는 무료 리소스를 활용하여 완전관리형 쿠버네티스 클러스터를 만들어 줍니다.

해당 코드에서 만드는 리소스는 다음과 같습니다.
- [VCN](https://www.oracle.com/kr/cloud/networking/virtual-cloud-network/) (서브넷 및 Security List 포함)
- [Oracle Kubernetes Engine](https://www.oracle.com/kr/cloud/cloud-native/kubernetes-engine/) 베이직 클러스터
- 2개의 VM.Standard.A1.Flex 인스턴스를 포함하는 워커 노드 풀 (2 OCPU, 12GB RAM Each)
- 해당 클러스터에 접근하기 위해 필요한 Bastion Host와 IAM 규칙 (VM.Standard.E2.1.Micro 평생 무료 활용)

## 사용 방법
1. [Terraform](https://www.terraform.io/downloads.html)을 설치합니다.
2. `terraform.tfvars.example` 파일을 참고하여 `terraform.tfvars` 파일을 생성하고 액세스 정보 등 필요한 정보를 입력합니다.
3. `terraform init` 명령어를 실행하여 필요한 플러그인을 설치합니다.
4. `terraform apply` 명령어를 실행하여 리소스를 생성합니다.

## 클러스터에 접근하는 방법
4번까지의 과정을 완료하면 쉽게 클러스터에 접근할 수 있습니다.

Oracle Cloud Infrastructure 대시보드에서 Bastion Host의 Public IP를 확인하고, outputs 디렉터리에 생성된 SSH 키를 이용하여 접속합니다. (기본 사용자명은 `ubuntu`입니다.)

Cloud-Init 스크립트를 활용해 모든 설정을 다 마쳐 놓도록 설계되어 있어, 클러스터에 접근하려면 Bastion Host에 접속하여 `kubectl` 명령어만 사용하면 됩니다.

Bastion Host에는 최신 버전의 kubectl, helm, oci-cli가 설치되어 있습니다.

## 주의 사항
- 해당 인프라는 평생 무료로 제공되는 200GB의 [Block Volume](https://www.oracle.com/kr/cloud/storage/block-volumes/)을 모두 사용하도록 설계되었습니다. 기존 인프라에서 블록 볼륨을 사용하고 있는 경우 요금이 청구될 수 있습니다.
- 해당 인프라에 포함된 Security List는 기본 클러스터 운영에 꼭 필요한 최소 권한으로 구성되어 있습니다. 사용 사례에 따라 규칙 추가가 필요할 수 있습니다.