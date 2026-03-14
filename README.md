
# 나빌 입력기 사용
* emacs 내장입력기와 비슷하게 한글 입력하는 방식 -> 두벌식 연속 입력(?)
* 나는 입력방식이 emacs와 비슷한 것을 선호(macOS, Phone)
* 가벼움(한자, 특수기호 입력기능 없다)


# 한글사용자 숙명적 불편
* 고질적인 macOS와 emacs 사이에 겪는 한영전환 불편문제


# 개선(나빌)
* emacs 사용때 시스템 입력소스(navilIME) 영문 자동전환: 가장 큰 불편
* ㅆ 받침  추가 : "tt":Jongsung.Ssangsios 한 줄 추가
* 심볼 자동 치환: -> → → 등 10개 패턴 추가(기능 불안)
* emacs-plus 30.2, macOS 15.7.4


# 도움
* 저는 개발자가 아닙니다. 
* 한글자판 사용자가 키보드 전환에 관한 불편 개선코자 시작
* 다행히도 좋은 시대를 만나 AI 도움으로 불편 해결


# 빌드
* swift version 5 필수.(현재 ver6 에러)
```
cd ~/Build/NavilIMEforMac
rm -rf ~/Library/Developer/Xcode/DerivedData/NavilIME-*
xcodebuild -project NavilIME.xcodeproj \
           -scheme NavilIME \
           -configuration Release \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           SWIFT_VERSION=5 \
           build 2>&1 | tail -3
		   
```

# 감사
* 원작자이신 나빌레라 님께 감사의 말씀을 올립니다.
* https://github.com/navilera/NavilIMEforMac
