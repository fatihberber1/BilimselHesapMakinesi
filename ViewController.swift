//
//  ViewController.swift
//  BilimselHesapMakinesi
//
//  Created by Trakya14 on 13.05.2025.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var displayLabel: UILabel!

    // MARK: - State
    private var currentInput: String = ""
    private var firstOperand: Double?
    private var pendingOperator: String?
    private var history: [String] = []
    private var isRadians: Bool = false     // RAD/DEG modu
    private var memory: Double = 0           // Hafıza

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        clearAll()
    }

    // MARK: - Actions
    @IBAction func buttonTapped(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else { return }

        switch title {
        // 1) Rakamlar & Virgül
        case "0"..."9", ",":
            inputDigitOrComma(title)

        // 2) Aritmetik Operatörler
        case "+", "−", "×", "÷":
            inputOperator(title)

        // 3) Eşittir
        case "=":
            inputEquals()

        // 4) Temizle (C veya MC)
        case "C", "MC":
            clearAll()
            memory = 0

        // 5) Backspace
        case "⌫":
            backspace()

        // 6) İşaret Değiştir
        case "±":
            toggleSign()

        // 7) Yüzde
        case "%":
            applyPercentage()

        // 8) Memory Add (M+)
        case "M+":
            // Ekrandaki değeri hafızaya ekle, sonra hafızayı ekranda göster
            memory += parseValue(currentInput)
            currentInput = formatResult(memory)
            updateDisplay()

        // 9) Memory Subtract (M-)
        case "M-":
            // Ekrandaki değeri hafızadan çıkar, sonra hafızayı ekranda göster
            memory -= parseValue(currentInput)
            currentInput = formatResult(memory)
            updateDisplay()

        // 10) Memory Recall (MR)
        case "MR":
            // Hafızadaki değeri ekranda göster
            currentInput = formatResult(memory)
            updateDisplay()

        // 11) Geçmiş
        case "H":
            showHistory()

        // 12) RAD/DEG Toggle
        case "Rad":
            isRadians.toggle()
            updateDisplay()

        // 13) Bilimsel & Sabit Fonksiyonlar
        default:
            applyScientificFunction(title)
        }
    }

    // MARK: - Input Handling
    private func inputDigitOrComma(_ ch: String) {
        guard !(ch == "," && currentInput.contains(",")) else { return }
        currentInput += ch
        updateDisplay()
    }

    private func inputOperator(_ op: String) {
        if let pending = pendingOperator,
           let first = firstOperand,
           !currentInput.isEmpty
        {
            let second = parseValue(currentInput)
            let res = performOp(first, pending, second)
            history.append("\(formatResult(first)) \(pending) \(formatResult(second)) = \(formatResult(res))")
            firstOperand = res
        } else {
            firstOperand = parseValue(currentInput)
        }
        pendingOperator = op
        currentInput = ""
        updateDisplay()
    }

    private func inputEquals() {
        guard let pending = pendingOperator,
              let first = firstOperand else { return }
        let second = parseValue(currentInput)
        let res = performOp(first, pending, second)
        history.append("\(formatResult(first)) \(pending) \(formatResult(second)) = \(formatResult(res))")
        currentInput = formatResult(res)
        memory = res       // Hesap sonucu hafızaya otomatik kaydedilsin
        firstOperand = nil
        pendingOperator = nil
        updateDisplay()
    }

    private func performOp(_ a: Double, _ op: String, _ b: Double) -> Double {
        switch op {
        case "+": return a + b
        case "−": return a - b
        case "×": return a * b
        case "÷": return b == 0 ? Double.infinity : a / b
        default:  return b
        }
    }

    private func updateDisplay() {
        let prefix = isRadians ? "rad " : ""
        if let first = firstOperand, let op = pendingOperator {
            displayLabel.text = "\(prefix)\(formatResult(first))\(op)\(currentInput)"
        } else {
            displayLabel.text = prefix + (currentInput.isEmpty ? "0" : currentInput)
        }
    }

    // MARK: - Auxiliary
    private func clearAll() {
        currentInput = ""
        firstOperand = nil
        pendingOperator = nil
        isRadians = false
        displayLabel.text = "0"
    }

    private func backspace() {
        guard !currentInput.isEmpty else { return }
        currentInput.removeLast()
        updateDisplay()
    }

    private func toggleSign() {
        let val = parseValue(currentInput)
        currentInput = formatResult(-val)
        updateDisplay()
    }

    private func applyPercentage() {
        let val = parseValue(currentInput)
        currentInput = formatResult(val / 100)
        updateDisplay()
    }

    private func showHistory() {
        let msg = history.isEmpty
            ? "Henüz geçmiş işleminiz yok."
            : history.reversed().joined(separator: "\n")
        let alert = UIAlertController(title: "Geçmiş İşlemler",
                                      message: msg,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Kapat", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Scientific & Constants
    private func applyScientificFunction(_ name: String) {
        switch name {
        case "e", "π":
            currentInput = name
        case "sin":
            let v = parseAngle(currentInput)
            currentInput = formatResult(sin(v))
        case "cos":
            let v = parseAngle(currentInput)
            currentInput = formatResult(cos(v))
        case "tan":
            let v = parseAngle(currentInput)
            currentInput = formatResult(tan(v))
        case "asin":
            let r = asin(clamp(parseAngle(currentInput)))
            currentInput = formatResult(isRadians ? r : r * 180 / .pi)
        case "acos":
            let r = acos(clamp(parseAngle(currentInput)))
            currentInput = formatResult(isRadians ? r : r * 180 / .pi)
        case "atan":
            let r = atan(parseAngle(currentInput))
            currentInput = formatResult(isRadians ? r : r * 180 / .pi)
        case "sinh":
            currentInput = formatResult(sinh(parseValue(currentInput)))
        case "cosh":
            currentInput = formatResult(cosh(parseValue(currentInput)))
        case "tanh":
            currentInput = formatResult(tanh(parseValue(currentInput)))
        case "ln":
            currentInput = formatResult(log(parseValue(currentInput)))
        case "log₁₀":
            currentInput = formatResult(log10(parseValue(currentInput)))
        case "x²":
            let v = parseValue(currentInput)
            currentInput = formatResult(v*v)
        case "x³":
            let v = parseValue(currentInput)
            currentInput = formatResult(v*v*v)
        case "√x":
            let v = parseValue(currentInput)
            currentInput = formatResult(v >= 0 ? sqrt(v) : v)
        case "³√x":
            currentInput = formatResult(cbrt(parseValue(currentInput)))
        case "eˣ":
            currentInput = formatResult(exp(parseValue(currentInput)))
        case "10ˣ":
            currentInput = formatResult(pow(10, parseValue(currentInput)))
        case "x!":
            currentInput = formatResult(factorial(of: Int(parseValue(currentInput))))
        default:
            return
        }
        updateDisplay()
    }

    private func parseValue(_ str: String) -> Double {
        switch str {
        case "e":  return M_E
        case "π":  return Double.pi
        default:   return Double(str.replacingOccurrences(of: ",", with: ".")) ?? 0
        }
    }

    private func parseAngle(_ str: String) -> Double {
        let v = parseValue(str)
        return isRadians ? v : v * .pi/180
    }

    private func clamp(_ x: Double) -> Double {
        return max(-1, min(1, x))
    }

    private func factorial(of n: Int) -> Double {
        return (1...max(n,1)).map(Double.init).reduce(1, *)
    }

    private func formatResult(_ v: Double) -> String {
        return String(format: "%g", v).replacingOccurrences(of: ".", with: ",")
    }
}
