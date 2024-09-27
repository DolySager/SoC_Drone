# Vitis Workspace에서 외부 파일을 연결하는 방법
리포지토리에는 소스파일만 보관하기 위해 Vitis Workspace와 소스파일 보관 장소를 분리하였습니다.<br>
따라서 리포지토리 외부의 Vitis Workspace에 리포지토리 내부의 파일을 연결시켜야 합니다.<br>

### 1. 원하는 Vitis Workspace 열기

### 2. Platform 프로젝트와 System 프로젝트 준비
<img alt="Vitis Tutorial Step 1" src = "/README_img/vitis_tutorial_1.png" height="320"/>

### 3. System 프로젝트 내의 App 프로젝트 폴더 중 "src" 폴더 오른쪽 클릭 후 "Delete" 클릭
<img alt="Vitis Tutorial Step 2" src = "/README_img/vitis_tutorial_2.png" height="320"/>

### 4. 확인 메세지 출력 시 "OK" 클릭하여 폴더 삭제
<img alt="Vitis Tutorial Step 3" src = "/README_img/vitis_tutorial_3.png" height="160"/>

### 5. Explorer 탭 내부에서 오른쪽 클릭 후 "New" -> "Folder" 클릭
오른쪽 클릭 장소는 Explorer 탭 내부 어디든 가능함 <br><br>
<img alt="Vitis Tutorial Step 4" src = "/README_img/vitis_tutorial_4.png" height="320"/>

### 6. Parent Folder 선택할 때 App 프로젝트 폴더 선택
**중요함: Platform 이나 System 프로젝트 폴더 선택 않도록 주의** <br><br>
<img alt="Vitis Tutorial Step 5" src = "/README_img/vitis_tutorial_5.png" height="320"/>

### 7. "Advanced" 클릭 -> "Link to alternate location (Llinked Folder)" 선택 -> "Browse..." 클릭
<img alt="Vitis Tutorial Step 6" src = "/README_img/vitis_tutorial_6.png" height="320"/>

### 8. 리포지토리 Vitis 프로젝트 폴더 내부의 src 폴더 한번만 클릭 후 "폴더 선택" 클릭
<img alt="Vitis Tutorial Step 7" src = "/README_img/vitis_tutorial_7.png" height="240"/>

### 9. "Finish" 버튼 클릭
<img alt="Vitis Tutorial Step 8" src = "/README_img/vitis_tutorial_8.png" height="320"/>

### 10. 프로젝트 폴더 내부에 화살표 표시된 폴더 아이콘의 src 폴더 확인
<img alt="Vitis Tutorial Step 9" src = "/README_img/vitis_tutorial_9.png" height="320"/>

<br><br>
위 작업 후에 Vitis Workspace와 소스파일이 별도로 관리됩니다. <br><br>

**중요: XSA 파일이 변경되면 수동으로 업데이트 해주어야 합니다.**
