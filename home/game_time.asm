ResetGameTime::
	xor a
	ld [wGameTimeCap], a
	ld [wGameTimeHours], a
	ld [wGameTimeHours + 1], a
	ld [wGameTimeMinutes], a
	ld [wGameTimeSeconds], a
	ld [wGameTimeFrames], a
	ret

GameTimer::
	nop

; Increment the game timer by one frame.
; The game timer is capped at 999:59:59.00.

; Don't update if game logic is paused.
	ld a, [wGameLogicPaused]
	and a
	ret nz

; Is the timer paused?
	ld hl, wGameTimerPause
	bit GAMETIMERPAUSE_TIMER_PAUSED_F, [hl]
	ret z

; Is the timer already capped?
	ld hl, wGameTimeCap
	bit 0, [hl]
	ret nz

; +1 frame
	ld hl, wGameTimeFrames
	ld a, [hl]
	inc a

	cp 60 ; frames/second
	jr nc, .second

	ld [hl], a
	ret

.second
	xor a
	ld [hl], a

;; kroc - noRTC Patch
;; the game timer has increased by 1 second
;; increase the "fake" RTC by 6 seconds (24 in-game hours will pass in 4 real-world hours)
;; this does not affect the rate of the "hours played" time which remains real-time.
if DEF(NO_RTC)
rept NO_RTC_SPEEDUP
	call UpdateNoRTC
endr
endc

; +1 second
	ld hl, wGameTimeSeconds
	ld a, [hl]
	inc a

	cp 60 ; seconds/minute
	jr nc, .minute

	ld [hl], a
	ret

.minute
	xor a
	ld [hl], a

; +1 minute
	ld hl, wGameTimeMinutes
	ld a, [hl]
	inc a

	cp 60 ; minutes/hour
	jr nc, .hour

	ld [hl], a
	ret

.hour
	xor a
	ld [hl], a

; +1 hour
	ld a, [wGameTimeHours]
	ld h, a
	ld a, [wGameTimeHours + 1]
	ld l, a
	inc hl

; Cap the timer after 1000 hours.
	ld a, h
	cp HIGH(1000)
	jr c, .ok

	ld a, l
	cp LOW(1000)
	jr c, .ok

	ld hl, wGameTimeCap
	set 0, [hl]

	ld a, 59 ; 999:59:59.00
	ld [wGameTimeMinutes], a
	ld [wGameTimeSeconds], a
	ret

.ok
	ld a, h
	ld [wGameTimeHours], a
	ld a, l
	ld [wGameTimeHours + 1], a
	ret

;; kroc - noRTC Patch
if DEF(NO_RTC)
UpdateNoRTC::
;; set our modulus
	ld a, 60
	ld b, a

	ld hl, wNoRTCSeconds

; +1 second
	ld a, b
	inc [hl]
	sub [hl]
	ret nz
	ld [hld], a

; +1 minute
	ld a, b
	inc [hl]
	sub [hl]
	ret nz
	ld [hld], a

; +1 hour
;; 24 hours to a day
	ld a, 24
	inc [hl]
	sub [hl]
	ret nz
	ld [hld], a

;; the RTC stores days as a 16-bit number, it does not handle months
;; and so on as that's calculated by the game from the start date.
;; note that this is different than GameTime which just counts hours and not days

; +1 day
;; increase the number of days (low)
	inc [hl]
;; if that didn't overflow, leave
	ret nc
;; TODO: only five bits are available on the hi-byte (the others are flags)
;; increase the days (hi)
	inc hl
	inc [hl]

	ret
endc
