//
//  ChallengeButtonStyleProvider.swift
//  Habitica
//
//  Created by Elliot Schrock on 1/24/18.
//  Copyright © 2018 HabitRPG Inc. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import Habitica_Models

protocol ChallengeButtonStyleProvider: HRPGButtonAttributeProvider, HRPGButtonModelInputs {
    var challengeUpdatedSignal: Signal<Bool, NoError> { get }
}

class JoinLeaveButtonAttributeProvider: ChallengeButtonStyleProvider {
    
    private let socialRepository = SocialRepository()
    
    let challengeProperty = MutableProperty<ChallengeProtocol?>(nil)
    let challengeMembershipProperty = MutableProperty<ChallengeMembershipProtocol?>(nil)
    
    let buttonStateSignal: Signal<ChallengeButtonState, NoError>
    let buttonPressedProperty = MutableProperty(())
    
    let challengeUpdatedSignal: Signal<Bool, NoError>
    let challengeUpdatedProperty = MutableProperty(())
    
    let promptProperty = MutableProperty<UIViewController?>(nil)
    
    let bgColorSignal: Signal<UIColor, NoError>
    let titleSignal: Signal<String, NoError>
    let enabledSignal: Signal<Bool, NoError>
    
    init(_ challenge: ChallengeProtocol?) {
        challengeUpdatedSignal = challengeUpdatedProperty.signal.map { _ in true }
        
        let joinableChallengeSignal = challengeMembershipProperty.signal
            .filter({ (membership) -> Bool in
                return membership == nil
            }).map { _ in ChallengeButtonState.join }
        let leaveableChallengeSignal = challengeMembershipProperty.signal
            .filter({ (membership) -> Bool in
                return membership != nil
            }).map { _ in ChallengeButtonState.leave }
        
        buttonStateSignal = Signal.merge(joinableChallengeSignal, leaveableChallengeSignal).sample(on: triggerStyleProperty.signal)
        
        let joinStyleSignal = buttonStateSignal.filter { $0 == .join }
        let leaveStyleSignal = buttonStateSignal.filter { $0 == .leave }
        
        let greenSignal = joinStyleSignal.map { _ in UIColor.green100() }
        let joinTitleSignal = joinStyleSignal.signal.map { _ in "Join Challenge" }
        
        let redSignal = leaveStyleSignal.map { _ in UIColor.red100() }
        let leaveTitleSignal = leaveStyleSignal.signal.map { _ in "Leave Challenge" }
        
        bgColorSignal = Signal.merge(greenSignal, redSignal)
        titleSignal = Signal.merge(joinTitleSignal, leaveTitleSignal)
        enabledSignal = buttonStateSignal.map { $0 != .publishDisabled }
        
        buttonStateSignal.sample(on: buttonPressedProperty.signal).observeValues { [weak self] (state) in
            if state == .join {
                self?.socialRepository.joinChallenge(challengeID: self?.challengeProperty.value?.id ?? "").observeCompleted {
                    self?.challengeUpdatedProperty.value = ()
                }
            } else {
                self?.promptProperty.value = self?.leavePrompt()
            }
        }
        
        challengeProperty.value = challenge
    }
    
    func leavePrompt() -> UIViewController {
        let alert = HabiticaAlertController(title: NSLocalizedString("Leave Challenge?", comment: ""),
                                            message: NSLocalizedString("Do you want to leave the challenge and keep or delete the tasks?", comment: ""))
        alert.addAction(title: NSLocalizedString("Keep tasks", comment: ""), style: .default, handler: {[weak self] (_) in
            self?.socialRepository.leaveChallenge(challengeID: self?.challengeProperty.value?.id ?? "", keepTasks: true).observeCompleted {
                self?.challengeUpdatedProperty.value = ()
            }
        })
        alert.addAction(title: NSLocalizedString("Delete tasks", comment: ""), style: .default, handler: {[weak self] (_) in
            self?.socialRepository.leaveChallenge(challengeID: self?.challengeProperty.value?.id ?? "", keepTasks: false).observeCompleted {
                self?.challengeUpdatedProperty.value = ()
            }
        })
        alert.addAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (_) in })
        
        return alert
    }
    
    // MARK: HRPGButtonAttributeProvider functions
    
    let triggerStyleProperty: MutableProperty = MutableProperty(())
    func triggerStyle() {
        self.triggerStyleProperty.value = ()
    }
    
    // MARK: HRPGButtonModelInputs functions
    
    func hrpgButtonPressed() {
        buttonPressedProperty.value = ()
    }
}

class PublishButtonAttributeProvider: HRPGButtonAttributeProvider, HRPGButtonModelInputs {
    let challengeProperty: MutableProperty<ChallengeProtocol?> = MutableProperty<ChallengeProtocol?>(nil)
    
    let buttonStateSignal: Signal<ChallengeButtonState, NoError>
    let buttonPressedProperty = MutableProperty(())
    
    let bgColorSignal: Signal<UIColor, NoError>
    let titleSignal: Signal<String, NoError>
    let enabledSignal: Signal<Bool, NoError>
    
    init(_ challenge: ChallengeProtocol?) {
        let publishableChallengeSignal = challengeProperty.signal
            .filter({ (challenge) -> Bool in
                return challenge?.shouldBeUnpublishable() == true
            }).map { _ in ChallengeButtonState.publishEnabled }
        let unpublishableChallengeSignal = challengeProperty.signal
            .filter({ (challenge) -> Bool in
                return challenge?.shouldBeUnpublishable() == true
            }).map { _ in ChallengeButtonState.publishDisabled }
        
        buttonStateSignal = Signal.merge(publishableChallengeSignal, unpublishableChallengeSignal).sample(on: triggerStyleProperty.signal)
        
        let publishSignal = buttonStateSignal.filter { $0 == .publishEnabled || $0 == .publishDisabled }
        
        bgColorSignal = publishSignal.map { _ in UIColor.purple300() }
        titleSignal = publishSignal.signal.map { _ in "Publish Challenge" }
        enabledSignal = buttonStateSignal.map { $0 != .publishDisabled }
        
        buttonStateSignal.sample(on: buttonPressedProperty.signal).observeValues { (state) in
            if state == .publishEnabled {
                //TODO: publish challenge
            }
        }
        
        challengeProperty.value = challenge
    }
    
    // MARK: HRPGButtonAttributeProvider functions
    
    let triggerStyleProperty = MutableProperty(())
    func triggerStyle() {
        triggerStyleProperty.value = ()
    }
    
    // MARK: HRPGButtonModelInputs functions
    
    func hrpgButtonPressed() {
        buttonPressedProperty.value = ()
    }
}

class ParticipantsButtonAttributeProvider: HRPGButtonAttributeProvider, HRPGButtonModelInputs {
    let challengeProperty: MutableProperty<ChallengeProtocol?> = MutableProperty<ChallengeProtocol?>(nil)
    
    let buttonStateSignal: Signal<ChallengeButtonState, NoError>
    let buttonPressedProperty = MutableProperty(())
    
    let bgColorSignal: Signal<UIColor, NoError>
    let titleSignal: Signal<String, NoError>
    let enabledSignal: Signal<Bool, NoError>
    
    init(_ challenge: ChallengeProtocol) {
        let participantsViewableSignal = challengeProperty.signal
            .filter({ (challenge) -> Bool in
                return challenge?.isOwner() == true && challenge?.isPublished() == true
            })
            .map { _ in ChallengeButtonState.viewParticipants }
        
        buttonStateSignal = participantsViewableSignal.sample(on: triggerStyleProperty.signal)
        
        let participantsSignal =  buttonStateSignal.filter { $0 == .viewParticipants }
        
        bgColorSignal = participantsSignal.map { _ in UIColor.gray600() }
        titleSignal = participantsSignal.signal.map { _ in "View Participant Progress" }
        enabledSignal = buttonStateSignal.map { $0 != .publishDisabled }
    }
    
    // MARK: HRPGButtonAttributeProvider functions
    
    let triggerStyleProperty = MutableProperty(())
    func triggerStyle() {
        triggerStyleProperty.value = ()
    }
    
    // MARK: HRPGButtonModelInputs functions
    
    func hrpgButtonPressed() {
        buttonPressedProperty.value = ()
    }
}

class EndChallengeButtonAttributeProvider: HRPGButtonAttributeProvider, HRPGButtonModelInputs {
    let challengeProperty: MutableProperty<ChallengeProtocol?> = MutableProperty<ChallengeProtocol?>(nil)
    
    let buttonStateSignal: Signal<ChallengeButtonState, NoError>
    let buttonPressedProperty = MutableProperty(())
    
    let bgColorSignal: Signal<UIColor, NoError>
    let titleSignal: Signal<String, NoError>
    let enabledSignal: Signal<Bool, NoError>
    
    init(_ challenge: ChallengeProtocol) {
        let endableSignal = challengeProperty.signal
            .filter({ (challenge) -> Bool in
                return challenge?.isOwner() == true
            })
            .map { _ in ChallengeButtonState.endChallenge }
        
        buttonStateSignal = endableSignal.sample(on: triggerStyleProperty.signal)
        
        let endSignal =  buttonStateSignal.filter { $0 == .endChallenge }
        
        bgColorSignal = endSignal.map { _ in UIColor.red100() }
        titleSignal = endSignal.signal.map { _ in "End Challenge" }
        enabledSignal = buttonStateSignal.map { $0 != .publishDisabled }
    }
    
    // MARK: HRPGButtonAttributeProvider functions
    
    let triggerStyleProperty = MutableProperty(())
    func triggerStyle() {
        triggerStyleProperty.value = ()
    }
    
    // MARK: HRPGButtonModelInputs functions
    
    func hrpgButtonPressed() {
        buttonPressedProperty.value = ()
    }
}
