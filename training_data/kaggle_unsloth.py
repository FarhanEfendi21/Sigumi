# Install via Kaggle Notebook Terminal / Cell:
!pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git"
!pip install --no-deps xformers trl peft accelerate bitsandbytes

from unsloth import FastLanguageModel
import torch
from datasets import load_dataset
from trl import SFTTrainer
from transformers import TrainingArguments
from unsloth.chat_templates import get_chat_template

max_seq_length = 2048
dtype = None 
load_in_4bit = True # Wajib True untuk VRAM 16GB (Kaggle T4)

# 1. Load Model (Gemma 4-e2b-it)
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "unsloth/gemma-4-e2b-it",
    max_seq_length = max_seq_length,
    dtype = dtype,
    load_in_4bit = load_in_4bit,
)

# 2. Add LoRA
model = FastLanguageModel.get_peft_model(
    model,
    r = 16, 
    target_modules = ["q_proj", "k_proj", "v_proj", "o_proj",
                      "gate_proj", "up_proj", "down_proj"],
    lora_alpha = 16,
    lora_dropout = 0, 
    bias = "none",
    use_gradient_checkpointing = "unsloth",
    random_state = 3407,
    use_rslora = False,
    loftq_config = None,
)

# 3. Format Dataset (Gemma Chat Format)
tokenizer = get_chat_template(
    tokenizer,
    chat_template = "gemma",
    mapping = {"role": "role", "content": "content", "user": "user", "assistant": "assistant", "system": "system"}
)

def formatting_prompts_func(examples):
    convos = examples["messages"]
    texts = [tokenizer.apply_chat_template(convo, tokenize=False, add_generation_prompt=False) for convo in convos]
    return {"text": texts}

# Load JSONL yang sudah kita buat
dataset = load_dataset("json", data_files="sigumi_training_data.jsonl", split="train")
dataset = dataset.map(formatting_prompts_func, batched=True)

# 4. Config SFT Trainer
trainer = SFTTrainer(
    model = model,
    tokenizer = tokenizer,
    train_dataset = dataset,
    dataset_text_field = "text",
    max_seq_length = max_seq_length,
    dataset_num_proc = 2,
    packing = False,
    args = TrainingArguments(
        per_device_train_batch_size = 2,
        gradient_accumulation_steps = 4,
        warmup_steps = 5,
        num_train_epochs = 3, # Training penuh (bisa diganti max_steps)
        learning_rate = 2e-4,
        fp16 = not torch.cuda.is_bf16_supported(),
        bf16 = torch.cuda.is_bf16_supported(),
        logging_steps = 10,
        optim = "adamw_8bit",
        weight_decay = 0.01,
        lr_scheduler_type = "linear",
        seed = 3407,
        output_dir = "outputs",
    ),
)

# 5. Mulai Training
trainer_stats = trainer.train()

# 6. Save LoRA Model
model.save_pretrained("sigumi_lora_model")
tokenizer.save_pretrained("sigumi_lora_model")

# 7. Export ke GGUF (q4_k_m sangat optimal untuk PC/Mobile)
print("⏳ Mengekspor model ke format GGUF (Q4_K_M)...")
model.save_pretrained_gguf("sigumi_gguf_model", tokenizer, quantization_method = "q4_k_m")

print("✅ Training & Export selesai. GGUF disimpan di folder 'sigumi_gguf_model'")
