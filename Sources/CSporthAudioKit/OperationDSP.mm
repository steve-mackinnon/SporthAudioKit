// Copyright AudioKit. All Rights Reserved.

#include "CSporthAudioKit.h"
#include "SoundpipeDSPBase.h"
#include "ParameterRamper.h"
#include "Soundpipe.h"
#include "plumber.h"
#include <cmath>
#include <string>

enum OperationParameter : AUParameterAddress {
    OperationParameter1,
    OperationParameter2,
    OperationParameter3,
    OperationParameter4,
    OperationParameter5,
    OperationParameter6,
    OperationParameter7,
    OperationParameter8,
    OperationParameter9,
    OperationParameter10,
    OperationParameter11,
    OperationParameter12,
    OperationParameter13,
    OperationParameter14,
    
    OperationTrigger
};

float midiNoteToFrequency(uint8_t note) {
    return std::pow(2.0, (static_cast<float>(note) - 69.0) / 12.0) * 440.f;
}

class OperationDSP : public SoundpipeDSPBase {
private:
    plumber_data pd;
    std::string sporthCode;
    ParameterRamper rampers[OperationParameter14];

public:
    OperationDSP(bool hasInput = false) : SoundpipeDSPBase(hasInput, /*canProcessInPlace*/!hasInput) {
        for(int i=0;i<OperationTrigger;++i) {
            parameters[i] = &rampers[i];
        }
        isStarted = hasInput;
    }

    void setSporth(const char *sporth) {
        sporthCode = sporth;
    }

    void init(int channelCount, double sampleRate) override {
        SoundpipeDSPBase::init(channelCount, sampleRate);
        plumber_register(&pd);
        plumber_init(&pd);

        pd.sp = sp;
        if (!sporthCode.empty()) {
            plumber_parse_string(&pd, sporthCode.c_str());
            plumber_compute(&pd, PLUMBER_INIT);
        }
    }

    void deinit() override {
        SoundpipeDSPBase::deinit();
        plumber_clean(&pd);
    }

    void reset() override {
        SoundpipeDSPBase::reset();
        if (!isInitialized) return;
        plumber_init(&pd);

        pd.sp = sp;
        if (!sporthCode.empty()) {
            plumber_parse_string(&pd, sporthCode.c_str());
            plumber_compute(&pd, PLUMBER_INIT);
        }
    }

    void handleMIDIEvent(AUMIDIEvent const& midiEvent) override {
        uint8_t status = midiEvent.data[0] & 0xF0;
        if(status == MIDI_NOTE_ON) {
            pd.p[OperationTrigger] = 1.0;
            // Hack: use parameter 14 to shuttle over the midi note
            pd.p[OperationParameter14] = midiNoteToFrequency(midiEvent.data[1]);
        }
    }

    void process(FrameRange range) override {
        for (int i : range) {

            if(!inputBufferLists.empty()) {
                for (int channel = 0; channel < channelCount; ++channel) {
                    if (channel < 2) {
                        pd.p[channel+OperationTrigger] = inputSample(channel, i);
                    }
                }
            }

            for(int i=0;i<OperationParameter14;++i) {
                pd.p[i] = rampers[i].getAndStep();
            }

            plumber_compute(&pd, PLUMBER_COMPUTE);

            for (int channel = 0; channel < channelCount; ++channel) {
                outputSample(channel, i) = sporth_stack_pop_float(&pd.sporth.stack);
            }

            pd.p[OperationTrigger] = 0.0;
        }
    }
};

void akOperationSetSporth(DSPRef dspRef, const char *sporth) {
    auto dsp = dynamic_cast<OperationDSP *>(dspRef);
    assert(dsp);
    dsp->setSporth(sporth);
}

struct OperationGeneratorDSP : public OperationDSP {
    OperationGeneratorDSP() : OperationDSP(/*hasInput*/false) { }
};

struct OperationEffectDSP : public OperationDSP {
    OperationEffectDSP() : OperationDSP(/*hasInput*/true) { }
};

AK_REGISTER_DSP(OperationGeneratorDSP, "cstg")
AK_REGISTER_DSP(OperationEffectDSP, "cstm")
AK_REGISTER_PARAMETER(OperationParameter1)
AK_REGISTER_PARAMETER(OperationParameter2)
AK_REGISTER_PARAMETER(OperationParameter3)
AK_REGISTER_PARAMETER(OperationParameter4)
AK_REGISTER_PARAMETER(OperationParameter5)
AK_REGISTER_PARAMETER(OperationParameter6)
AK_REGISTER_PARAMETER(OperationParameter7)
AK_REGISTER_PARAMETER(OperationParameter8)
AK_REGISTER_PARAMETER(OperationParameter9)
AK_REGISTER_PARAMETER(OperationParameter10)
AK_REGISTER_PARAMETER(OperationParameter11)
AK_REGISTER_PARAMETER(OperationParameter12)
AK_REGISTER_PARAMETER(OperationParameter13)
AK_REGISTER_PARAMETER(OperationParameter14)
