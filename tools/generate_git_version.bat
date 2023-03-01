WHERE git
IF %ERRORLEVEL% EQU 0 (
	IF EXIST ../.git/ (
	  echo | set /p dummyName=#define GIT_BRANCH > ../src/gitinfo.h
	  git rev-parse --abbrev-ref HEAD >> ../src/gitinfo.h

	  echo | set /p dummyName=#define GIT_VERSION >> ../src/gitinfo.h
	  git describe --abbrev=0 --tag >> ../src/gitinfo.h

	  echo | set /p dummyName=#define GIT_COMMITS >> ../src/gitinfo.h
	  git rev-list --count head >> ../src/gitinfo.h
	)
)