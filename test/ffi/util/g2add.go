package main

import (
	"fmt"
	"os"
	"strings"
	"math/big"
	"github.com/consensys/gnark-crypto/ecc/bn254"
)

func main() {
	//parse args
	arg1 := os.Args[1]
	arg2 := os.Args[2]
	arg3 := os.Args[3]
	arg4 := os.Args[4]
	arg5 := os.Args[5]
	arg6 := os.Args[6]
	arg7 := os.Args[7]
	arg8 := os.Args[8]

	//set args to g2 point
	g2in1 := new(bn254.G2Affine)
    g2in1.X.SetString(arg1, arg2)
    g2in1.Y.SetString(arg3, arg4)

	g2in2 := new(bn254.G2Affine)
	g2in2.X.SetString(arg5, arg6)
	g2in2.Y.SetString(arg7, arg8)

	//g2 mul
	g2out := new(bn254.G2Affine).Add(g2in1, g2in2)
	px := g2out.X.String()
	py := g2out.Y.String()

	//parse out point coords to big ints
	pxs := strings.Split(px, "+")	
	pxss := strings.Split(pxs[1], "*")

	pys := strings.Split(py, "+")	
	pyss := strings.Split(pys[1], "*")

	pxsInt := new(big.Int)
	pxsInt, _ = pxsInt.SetString(pxs[0], 10)

	pxssInt := new(big.Int)
	pxssInt, _ = pxssInt.SetString(pxss[0], 10)

	pysInt := new(big.Int)
	pysInt, _ = pysInt.SetString(pys[0], 10)

	pyssInt := new(big.Int)
	pyssInt, _ = pyssInt.SetString(pyss[0], 10)

	//swtich to print coord requested
	switch os.Args[9] {
	case "1":
		fmt.Printf("0x%064X", pxsInt)
	case "2":
		fmt.Printf("0x%064X", pxssInt)
	case "3":
		fmt.Printf("0x%064X", pysInt)
	case "4":
		fmt.Printf("0x%064X", pyssInt)
	}

}