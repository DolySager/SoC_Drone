# 비바도 프로젝트 사용법
리포지토리에는 소스파일만 보관하기 위해 프로젝트와 소스파일을 분리하였습니다. <br>
따라서 Vivado 프로젝트에서 외부의 파일을 연결해 주어야 합니다.

### 1. 원하는 비바도 프로젝트 생성 또는 이미 생성된 프로젝트 열기

### 2. 비바도 왼쪽의 "Add Sources" 클릭
<img alt="Vivado Tutorial Step 1" src = "/README_img/Vivado_tutorial_1.png" height="320"/>

### 3. "Add or create design sources" 선택 후 "Next" 클릭
<img alt="Vivado Tutorial Step 2" src = "/README_img/Vivado_tutorial_2.png" height="320"/>

### 4. "Add Files" 클릭
<img alt="Vivado Tutorial Step 3" src = "/README_img/Vivado_tutorial_3.png" height="320"/>

### 5. 리포지토리 내의 소스 파일 선택 후 "OK" 클릭
Block Diagram의 경우에는 .bd 파일 선택 <br>
Verilog 파일의 경우에는 .v 파일 선택 <br><br>
<img alt="Vivado Tutorial Step 4" src = "/README_img/Vivado_tutorial_4.png" height="320"/>

### 6. "Copy sources into project" 체크 해제 후 "Finish" 클릭
**중요함: 해당 체크 박스를 해제해야만 리포지토리 내의 파일을 직접 사용함**<br><br>
<img alt="Vivado Tutorial Step 5" src = "/README_img/Vivado_tutorial_5.png" height="320"/>

<br><br>
위 작업 후에 Vivado 프로젝트와 소스파일이 별도로 관리됩니다.
