.CODE

; Funkcja ApplyAverageFilter
; Argumenty:
; RCX - wska�nik na dane wej�ciowego obrazu
; RDX - wska�nik na dane wyj�ciowego obrazu
; R8  - szeroko�� obrazu
; R9  - wysoko�� obrazu
; Na stosie:
;  [rsp+8] - promie� filtru (int)

ApplyAverageFilter proc
    push rbx                ; Zapisujemy rejestry
    push rbp
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    ; Ustawienie stosu
    mov rbp, rsp

    ; Pobranie argument�w
    mov rsi, rcx            ; Wska�nik na dane wej�ciowe
    mov rdi, rdx            ; Wska�nik na dane wyj�ciowe
    mov r10, r8             ; Szeroko�� obrazu
    mov r11, r9             ; Wysoko�� obrazu
    mov eax, dword ptr [rbp+8] ; Promie� filtru (radius)
    mov r12d, eax           ; Promie� filtru

    ; Obliczenie wymiaru okna
    imul r12d, 2            ; Promie� * 2
    add r12d, 1             ; (2*radius + 1)

    xor rbx, rbx            ; Licznik wierszy Y
OuterLoop:
    xor rcx, rcx            ; Licznik kolumn X

InnerLoop:
    ; Reset sum dla R, G, B i licznika pikseli
    xor r8, r8              ; Suma R
    xor r9, r9              ; Suma G
    xor r15, r15            ; Suma B
    xor r13, r13            ; Licznik pikseli

    ; Iteracja w oknie filtru
    mov r14, rbx            ; Start Y
    sub r14, r12            ; Y - radius (teraz oba operandy maj� ten sam rozmiar)

FilterLoopY:
    mov rdx, r14
    add rdx, r12            ; Y + radius (64-bitowy rejestr u�yty zamiast 32-bitowego)
    cmp rdx, 0              ; Sprawd� doln� granic�
    jl SkipRow
    cmp rdx, r11            ; Sprawd� g�rn� granic�
    jge SkipRow

    mov r15, rcx            ; Start X
    sub r15, r12           ; X - radius

FilterLoopX:
    mov rdx, r15
    add rdx, r12           ; X + radius
    cmp rdx, 0              ; Sprawd� lew� granic�
    jl SkipPixel
    cmp rdx, r10            ; Sprawd� praw� granic�
    jge SkipPixel

    ; Obliczenie wska�nika do danych piksela
    mov rax, r14            ; Wiersz
    imul rax, r10           ; Wiersz * szeroko��
    add rax, r15            ; Kolumna
    imul rax, 3             ; Rozmiar piksela (RGB)

    ; Dodanie warto�ci R, G, B
    add r8b, byte ptr [rsi+rax]      ; Dodanie warto�ci R (8-bitowy rejestr)
    add r9b, byte ptr [rsi+rax+1]    ; Dodanie warto�ci G (8-bitowy rejestr)
    add r15b, byte ptr [rsi+rax+2]   ; Dodanie warto�ci B (8-bitowy rejestr)
    inc r13                         ; Licznik pikseli

SkipPixel:
    inc r15            ; Nast�pna kolumna w oknie
    cmp r15, rcx
    jl FilterLoopX

SkipRow:
    inc r14            ; Nast�pny wiersz w oknie
    cmp r14, rbx
    jl FilterLoopY

    ; �rednia pikseli
    test r13, r13      ; Sprawdzenie liczby pikseli
    jz SkipWrite       ; Uniknij dzielenia przez 0

    mov eax, r8d       ; Suma R
    cdq                ; Przygotowanie do dzielenia
    idiv r13d          ; R = R / liczba pikseli
    imul rax, rcx, 3                ; rax = rcx * 3
    mov byte ptr [rdi+rax], al      ; Zapisz warto�� AL do adresu

    mov eax, r9d       ; Suma G
    cdq
    idiv r13d          ; G = G / liczba pikseli
    imul rax, rcx, 3             ; rax = rcx * 3
    mov byte ptr [rdi+rax+1], al ; Zapisz warto�� AL do adresu (przesuni�cie +1)

    mov eax, r15d      ; Suma B
    cdq
    idiv r13d          ; B = B / liczba pikseli
    imul rax, rcx, 3             ; rax = rcx * 3
    mov byte ptr [rdi+rax+2], al ; Zapisz warto�� AL pod adresem (rdi + rax + 2)

SkipWrite:
    inc rcx
    cmp rcx, r10
    jl InnerLoop

    inc rbx
    cmp rbx, r11
    jl OuterLoop

    ; Przywr�cenie rejestr�w
    mov rsp, rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbp
    pop rbx

    ret
    
    ApplyAverageFilter endp

    END
